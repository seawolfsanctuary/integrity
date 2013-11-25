module Integrity
  class CoverageProvider
    Dir[File.dirname(__FILE__) + '/coverage_providers/*.rb'].each {|file| require file }

    def self.all
      [
        { :title => "(none)",   :value => "" },
        { :title => "SimpleCov HTML (<= 0.7.x)", :value => "SimplecovHtml" }
      ]
    end
  end
end
