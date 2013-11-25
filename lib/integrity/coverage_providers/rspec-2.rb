module Integrity
  module CoverageProviders
    class Rspec2
      attr_reader :build

      def initialize(build)
        @build = build
      end

      def locate_coverage_statistic
        line = @build.output.split("\n").last
        if line.length && line.scan(/coverage.*[1-9]+\.[0-9]+%/)
          percentages = line.scan(/[0-9]+\.[0-9]+%/)
          if !percentages.empty?
            return percentages.last.chomp("%").to_f
          end
        end
        return nil
      end
    end
  end
end
