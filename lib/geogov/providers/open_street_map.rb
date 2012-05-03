module Geogov

  class OpenStreetMap

    def initialize(url = "http://ojw.dev.openstreetmap.org")
      @url = url
    end

    def map_img(lat,long,options = {})
      options = {
        :w => 200,
        :h => 200,
        :z => 14,
        :mode => "export",
        :lat => lat,
        :lon => long,
        :show => 1
      }.merge(options)

      if options[:marker_lat] && options[:marker_lon]
        options[:mlat0] = options.delete(:marker_lat)
        options[:mlon0] = options.delete(:marker_lon)
      end

      params = Geogov.hash_to_params(options)

      "#{@url}/StaticMap?#{params}"
    end

    def map_href(lat,long,options = {})
      options = {
        :zoom => options[:z] || 14,
        :lat => lat,
        :lon => long,
        :layers => "M"
      }.merge(options)

      if options[:marker_lat] && options[:marker_lon]
        options[:mlat0] = options.delete(:marker_lat)
        options[:mlon0] = options.delete(:marker_lon)
      end

      params = Geogov.hash_to_params(options)

      "http://www.openstreetmap.org/?#{params}"
    end

  end


end
