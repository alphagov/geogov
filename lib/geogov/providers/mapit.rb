require 'cgi'
require 'uri'

module Geogov

  class Mapit

    class Method
      def initialize(url, params = [])
        @url = url
        @params = params
      end

      def to_url(base_url)
        url = "/#{@url}" unless /^\//.match(@url)
        params = @params.map { |p|
          p = p.join(",") if p.is_a?(Array)
          # Messy, but MapIt gets upset if you escape commas
          CGI::escape(p).gsub('%2C', ',')
        }
        url_path = "#{base_url}#{url}"
        url_path += "/#{params.join("/")}" if params.length > 0
        url_path += ".json"
        return url_path
      end

      def call(base_url)
        Geogov.get_json(self.to_url(base_url))
      end
    end

    def initialize(default_url = "http://mapit.mysociety.org")
      @base = default_url
    end

    def valid_mapit_methods
      [:postcode, :areas, :area, :point, :generations]
    end

    def respond_to?(sym)
      valid_mapit_methods.include?(sym) || super(sym)
    end

    def lat_lon_from_postcode(postcode)
      areas = areas_for_stack_from_postcode(postcode)
      areas[:point]
    end

    # Borrowed heavily from mapit's pylib/postcodes/views.py with some amendments based on
    # pylib/mapit/areas/models.py
    def translate_area_type_to_shortcut(area_type)
      if ['COP', 'LBW', 'LGE', 'MTW', 'UTE', 'UTW', 'DIW'].include?(area_type)
        return 'ward'
      elsif ['CTY', 'CED', 'MTD', 'UTA', 'DIS', 'LBO', 'LGD'].include?(area_type)
        return 'council'
      elsif area_type == 'EUR'
        return 'region'
      elsif area_type == 'WMC' # XXX Also maybe 'EUR', 'NIE', 'SPC', 'SPE', 'WAC', 'WAE', 'OLF', 'OLG', 'OMF', 'OMG')
        return 'WMC'
      end
    end

    def areas_for_stack_from_coords(lat, lon)
      query = self.point("4326", [lon, lat])
      results = {:point => {'lat' => lat, 'lon' => lon}}
      councils = { }
      
      query.each do |id, area_info|
        type = area_info['type'].upcase.to_sym
        level = translate_area_type_to_shortcut(area_info['type'])
        
        if level
          level = level.downcase.to_sym
          results[level] = [] unless results[level]
          level_info = area_info.select { |k, v| ["name", "id", "type"].include?(k) }
          level_info['ons'] = area_info['codes']['ons'] if area_info['codes'] && area_info['codes']['ons']
          results[level] << level_info
          results[:nation] = area_info['country_name'] if results[:nation].nil?
        end
        
        councils[type] = { 'name' => area_info['name'], 'type' => area_info['type'], 'id' => area_info['id'] }
      end

      return councils.merge results 
    end

    def areas_for_stack_from_postcode(postcode)
      query = self.postcode(postcode)
      results = {}

      if query && query['areas']

        query['areas'].each do |i, area|
          type = area['type'].to_sym
          results[type] = area
        end 

        query['shortcuts'].each do |typ, i|
          if i.is_a? Hash
            ids = i.values()
          else
            ids = [i]
          end
          ids.each do |id|
            area_info = query['areas'][id.to_s]
            level = typ.downcase.to_sym
            results[level] = [] unless results[level]
            level_info = area_info.select { |k, v| ["name", "id", "type"].include?(k) }
            level_info['ons'] = area_info['codes']['ons'] if area_info['codes'] && area_info['codes']['ons']
            results[level] << level_info
            results[:nation] = area_info['country_name'] if results[:nation].nil?
          end
        end
        lat, lon = query['wgs84_lat'], query['wgs84_lon']
        results[:point] = {'lat' => lat, 'lon' => lon}
      end
      return results
    end

    def centre_of_district(district_postcode)
      query = self.postcode("partial", district_postcode)
      if query
        lat, lon = query['wgs84_lat'], query['wgs84_lon']
        return {'lat' => lat, 'lon' => lon}
      end
    end

    def method_missing(method, *args, &block)
      if valid_mapit_methods.include?(method)
        Mapit::Method.new(method.to_s, args).call(@base)
      else
        super(method, *args, &block)
      end
    end

  end
end
