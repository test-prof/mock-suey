# frozen_string_literal: true

require "mock_suey/type_checks/sorbet"
require_relative "../fixtures/shared/tax_calculator_sorbet"

describe MockSuey::TypeChecks::Sorbet do
  subject(:checker) { described_class.new }

  context "with signatures" do
    let(:target) { instance_double("TaxCalculatorSorbet") }

    subject(:checker) do
      described_class.new
    end

    describe "type check without signatures" do
      skip "type-checks core classes" do
        # 'sorbet-runtime' does not include signatures for stdlib classes yet
        mcall = MockSuey::MethodCall.new(
          receiver_class: Array,
          method_name: :take,
          arguments: ["first"],
          mocked_obj: []
        )

        expect do
          checker.typecheck!(mcall)
        end.to raise_error(TypeError, /Expected.*Integer.*got.*String.*/)
      end

      def create_mcall(target)
        MockSuey::MethodCall.new(
          receiver_class: TaxCalculatorSorbet,
          method_name: :simple_test_no_sig,
          arguments: [120],
          mocked_obj: target
        )
      end

      it "when raise_on_missing false" do
        allow(target).to receive(:simple_test_no_sig).and_return(333)
        mcall = create_mcall(target)

        expect do
          checker.typecheck!(mcall)
        end.not_to raise_error
      end

      it "when raise_on_missing true" do
        allow(target).to receive(:simple_test_no_sig).and_return(333)
        mcall = create_mcall(target)

        expect do
          checker.typecheck!(mcall, raise_on_missing: true)
        end.to raise_error(MockSuey::TypeChecks::MissingSignature, /.*set raise_on_missing_types to false.*/)
      end
    end

    describe "type check argument type" do
      describe "check for singleton classes" do
        let(:sc) { TaxCalculatorSorbet.singleton_class }

        it "type-checks singleton classes" do
          mcall = MockSuey::MethodCall.new(
            receiver_class: sc,
            method_name: :singleton_test,
            arguments: [1],
            return_value: 333,
            mocked_obj: sc
          )

          expect do
            checker.typecheck!(mcall)
          end.not_to raise_error
        end

        it "type-checks mocked singleton classes" do
          allow(sc).to receive(:singleton_test).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: sc,
            method_name: :singleton_test,
            arguments: [1],
            return_value: sc.singleton_test(1),
            mocked_obj: sc
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /Return value.*Expected.*Integer.*got.*String/)
        end
      end

      describe "for mocked instance methods" do
        it "when correct" do
          allow(target).to receive(:simple_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test,
            arguments: [120],
            mocked_obj: target
          )

          expect do
            checker.typecheck!(mcall)
          end.not_to raise_error
        end

        it "when incorrect" do
          allow(target).to receive(:simple_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test,
            arguments: ["120"],
            mocked_obj: target
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /Parameter.*val.*Expected.*Integer.*got.*String.*/)
        end

        it "when block is passed correctly" do
          allow(target).to receive(:simple_block).and_yield("444")
          block = proc { |_n| "333" }

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_block,
            arguments: [123],
            mocked_obj: target,
            block: block,
            return_value: "333"
          )

          expect(checker.typecheck!(mcall)).to eq("333")
          expect { checker.typecheck!(mcall) }.not_to raise_error
        end

        it "when no block has been passed" do
          allow(target).to receive(:simple_block).and_yield("444")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_block,
            arguments: [123],
            mocked_obj: target
          )

          expect { checker.typecheck!(mcall) }.to raise_error(TypeError)
        end
      end

      describe "for mocked class methods" do
        describe "initialize" do
          let(:target) { instance_double("AccountantSorbet") }

          it "called correctly" do
            allow(target).to receive(:initialize)

            mcall = MockSuey::MethodCall.new(
              receiver_class: AccountantSorbet,
              method_name: :initialize,
              arguments: [{tax_calculator: TaxCalculator.new}],
              mocked_obj: target
            )

            expect { checker.typecheck!(mcall) }.not_to raise_error
          end

          it "called incorrectly" do
            allow(target).to receive(:initialize)

            mcall = MockSuey::MethodCall.new(
              receiver_class: AccountantSorbet,
              method_name: :initialize,
              arguments: [{tax_calculator: "incorrect"}],
              mocked_obj: target
            )

            expect do
              checker.typecheck!(mcall)
            end.to raise_error(TypeError, /.*Parameter.*tax_calculator.*Expected.*TaxCalculator.*got.*String.*/)
          end
        end

        it "when correct" do
          allow(TaxCalculatorSorbet).to receive(:class_method_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :class_method_test,
            arguments: [120],
            mocked_obj: TaxCalculatorSorbet
          )

          expect { checker.typecheck!(mcall) }.not_to raise_error
        end

        it "when incorrect" do
          allow(TaxCalculatorSorbet).to receive(:class_method_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :class_method_test,
            arguments: ["120"],
            mocked_obj: TaxCalculatorSorbet
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /Parameter.*val.*Expected.*Integer.*got.*String.*/)
        end
      end
    end

    describe "type check return type" do
      describe "for mocked instance methods" do
        it "when simple type is correct" do
          allow(target).to receive(:simple_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test,
            arguments: [120],
            mocked_obj: target,
            return_value: 333
          )

          expect(checker.typecheck!(mcall)).to eq(333)
          expect do
            checker.typecheck!(mcall)
          end.not_to raise_error
        end

        it "when simple type is incorrect" do
          allow(target).to receive(:simple_test).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test,
            arguments: [120],
            mocked_obj: target
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /.*Return value.*Expected.*Integer.*got.*String.*/)
        end

        it "when custom class is incorrect" do
          allow(target).to receive(:for_income).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :for_income,
            arguments: [120],
            mocked_obj: target
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /.*Return value.*Expected.*TaxCalculator::Result.*got.*String.*/)
        end

        it "when custom class is correct" do
          allow(target).to receive(:for_income).and_return(TaxCalculator::Result.new)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :for_income,
            arguments: [120],
            mocked_obj: target
          )

          expect { checker.typecheck!(mcall) }.not_to raise_error
        end

        it "does not raise type error when without runtime" do
          allow(target).to receive(:simple_test_no_runtime).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test_no_runtime,
            arguments: [120],
            mocked_obj: target,
            return_value: "incorrect"
          )

          expect do
            checker.typecheck!(mcall)
          end.not_to raise_error
        end

        it "raises error when added on_failure()" do
          allow(target).to receive(:simple_test_log_on_error).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :simple_test_log_on_error,
            arguments: [120],
            mocked_obj: target,
            return_value: "incorrect"
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError)
        end
      end

      describe "for mocked class methods" do
        it "when correct" do
          allow(TaxCalculatorSorbet).to receive(:class_method_test).and_return(333)

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :class_method_test,
            arguments: [120],
            mocked_obj: TaxCalculatorSorbet,
            return_value: 333
          )

          expect(checker.typecheck!(mcall)).to eq(333)
          expect do
            checker.typecheck!(mcall)
          end.not_to raise_error
        end

        it "when incorrect" do
          allow(TaxCalculatorSorbet).to receive(:class_method_test).and_return("incorrect")

          mcall = MockSuey::MethodCall.new(
            receiver_class: TaxCalculatorSorbet,
            method_name: :class_method_test,
            arguments: [120],
            mocked_obj: TaxCalculatorSorbet
          )

          expect do
            checker.typecheck!(mcall)
          end.to raise_error(TypeError, /.*Return value.*Expected.*Integer.*got.*String.*/)
        end
      end
    end
  end
end
