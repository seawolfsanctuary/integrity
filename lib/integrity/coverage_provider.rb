module Integrity
  class CoverageProvider
    Dir[File.dirname(__FILE__) + '/coverage_providers/*.rb'].each {|file| require file }

    def self.all
      [
        { :title => "(none)",   :value => "" },
        { :title => "RSpec v2", :value => "Rspec2" }
      ]
    end
  end
end
