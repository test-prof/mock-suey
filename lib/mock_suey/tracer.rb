# frozen_string_literal: true

module MockSuey
  class Tracer
    class PrependCollector
      attr_reader :tracer

      def initialize(tracer)
        @tracer = tracer
      end

      def module_for(klass, methods)
        tracer = self.tracer

        Module.new do
          define_method(:__mock_suey_tracer__) { tracer }

          methods.each do |mid|
            module_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{mid}(*args, **kwargs, &block)
                super.tap do |return_value|
                  arguments = args
                  arguments << kwargs unless kwargs.empty?

                  __mock_suey_tracer__ << MethodCall.new(
                    receiver_class: self.class,
                    method_name: __method__,
                    arguments:,
                    has_kwargs: !kwargs.empty?,
                    return_value:,
                    metadata: {
                      location: method(__method__).super_method.source_location.first
                    }
                  )
                end
              end
            RUBY
          end
        end
      end

      def setup(targets)
        targets.each do |klass, methods|
          mod = module_for(klass, methods)
          klass.prepend(mod)
        end
      end

      def stop
      end
    end

    class TracePointCollector
      attr_reader :tracer

      def initialize(tracer)
        @tracer = tracer
      end

      def setup(targets)
        tracer = self.tracer
        calls_stack = []

        @tp = TracePoint.trace(:call, :return) do |tp|
          methods = targets[tp.defined_class]
          next unless methods
          next unless methods.include?(tp.method_id)

          receiver_class, method_name = tp.defined_class, tp.method_id

          if tp.event == :call
            method = tp.self.method(method_name)
            arguments = []
            kwargs = {}

            method.parameters.each do |(type, name)|
              next if name == :** || name == :* || name == :&

              val = tp.binding.local_variable_get(name)

              case type
              when :req, :opt
                arguments << val
              when :keyreq, :key
                kwargs[name] = val
              when :rest
                arguments.concat(val)
              when :keyrest
                kwargs.merge!(val)
              end
            end

            arguments << kwargs unless kwargs.empty?

            call_obj = MethodCall.new(
              receiver_class:,
              method_name:,
              arguments:,
              has_kwargs: !kwargs.empty?,
              metadata: {
                location: method.source_location.first
              }
            )
            tracer << call_obj
            calls_stack << call_obj
          elsif tp.event == :return
            call_obj = calls_stack.pop
            call_obj.return_value = tp.return_value
          end
        end
      end

      def stop
        tp.disable
      end

      private

      attr_reader :tp
    end

    attr_reader :store, :targets, :collector

    def initialize(via: :prepend)
      @store = []
      @targets = Hash.new { |h, k| h[k] = [] }
      @collector =
        if via == :prepend
          PrependCollector.new(self)
        elsif via == :trace_point
          TracePointCollector.new(self)
        else
          raise ArgumentError, "Unknown tracing method: #{via}"
        end
    end

    def collect(klass, methods)
      targets[klass].concat(methods)
      targets[klass].uniq!
    end

    def start!
      collector.setup(targets)
    end

    def stop
      collector.stop
      total = store.size
      filter_calls!
      MockSuey.logger.debug "Collected #{store.size} real calls (#{total - store.size} were filtered)"
      store
    end

    def <<(call_obj)
      store << call_obj
    end

    private

    def filter_calls!
      store.reject! { mocked?(_1) }
    end

    def mocked?(call_obj)
      location = call_obj.metadata[:location]

      location.match?(%r{/lib/rspec/mocks/}) ||
        call_obj.return_value.is_a?(::RSpec::Mocks::Double) ||
        call_obj.arguments.any? { _1.is_a?(::RSpec::Mocks::Double) } ||
        call_obj.kwargs.values.any? { _1.is_a?(::RSpec::Mocks::Double) }
    end
  end
end
