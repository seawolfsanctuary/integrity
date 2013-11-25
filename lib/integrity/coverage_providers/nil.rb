module Integrity
  module CoverageProviders
    class Nil
      def initialize(*args)
      end

      def locate_coverage_statistic
        return nil
      end
    end
  end
end
