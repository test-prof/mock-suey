# frozen_string_literal: true

# Core class duplicates to freely mock and stub without interfiring with real classes

class TestHash < Hash
end

class TestArray < Array
end

class TestRegexp < Regexp
end
