lib = File.expand_path("../../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'test/unit'
require 'mocha'
require 'geogov'

class Test::Unit::TestCase
  class << self
    def test(name, &block)
     clean_name = name.gsub(/\s+/,'_')
     method = "test_#{clean_name.gsub(/\s+/,'_')}".to_sym
     already_defined = instance_method(method) rescue false
     raise "#{method} exists" if already_defined
     define_method(method, &block)
    end
  end
end
