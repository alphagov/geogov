$:.unshift(File.dirname(__FILE__))

require 'geogov/providers/open_street_map'
require 'geogov/providers/geonames'
require 'geogov/providers/google'
require 'geogov/providers/mapit'
require 'geogov/utils'
require 'geogov/geo_stack'
require 'geogov/fuzzy_point'
require 'geogov/providers/hostip'
require 'geogov/providers/dracos_gazetteer'

module Geogov

  def self.provider_for(method, instance)
    caching_instance = SimpleCache.new(instance)
    @@methods ||= {}
    @@methods[method] = caching_instance
    unless self.methods().include?(method)
      dispatcher = <<-EOS
        def #{method}(*args, &block)               
          @@methods[:#{method}].__send__(#{method.inspect}, *args, &block)  
        end 
      EOS
      module_eval(dispatcher)
    end  
  end

  def self.configure
    yield self
  end

  provider_for :nearest_place_name,            DracosGazetteer.new()
  
  provider_for :lat_lon_to_country,            Geonames.new()
  provider_for :centre_of_country,             Geonames.new()

  provider_for :centre_of_district,            Mapit.new()
  provider_for :areas_for_stack_from_postcode, Mapit.new()
  provider_for :areas_for_stack_from_coords,   Mapit.new()
  provider_for :lat_lon_from_postcode,         Mapit.new()

  provider_for :remote_location,               Hostip.new()  

  provider_for :map_img,                       Google.new()
  provider_for :map_href,                      Google.new()

  extend self
    
end

 

