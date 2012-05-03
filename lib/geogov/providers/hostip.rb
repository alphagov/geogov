require 'yaml'

module Geogov

  class Hostip
    def initialize
      @url = 'http://api.hostip.info/get_html.php'
    end

    def remote_location(ip_address)
      params = {:ip => ip_address, :position => true}
      results = Geogov.get(@url + "?" + Geogov.hash_to_params(params))
      return nil if results.nil?
      response = YAML.load(results + "\n")
      location = {}.tap do |h|
        h["lat"] = response['Latitude']
        h["lon"] = response['Longitude']
        h["city"], h["county"] = response['City'].split(', ')
        country = response['Country'].match(/\((\w+)\)$/)
        h["country"] = country[1] if country
      end
      return nil if location['city'] =~ /Unknown City/
      return nil if location['city'] =~ /Private Address/

      # I found these very unreliable, so better they're
      # not there to tempt anyone
      location.delete("city")
      location.delete("county")
      return location
    end

  end

end
