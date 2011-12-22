module Geogov
  class GeoStack

    attr_accessor :ward, :council, :nation, :country, :wmc, :lat, :lon, :friendly_name
    attr_reader :postcode, :fuzzy_point

    def initialize(&block)
      if block_given?
        yield self
      else
        self.fuzzy_point = calculate_fuzzy_point
      end
    end

    def calculate_fuzzy_point
      if self.lat and self.lon
        return FuzzyPoint.new(self.lat, self.lon, :point)
      end
     
      if self.postcode
        district = postcode.split(" ")[0]
        district_centre = Geogov.centre_of_district(district)
        if district_centre
          return FuzzyPoint.new(district_centre["lat"],district_centre["lon"],:postcode_district)
        end
      end

      if self.country
        country_centre = Geogov.centre_of_country(self.country)
        if country_centre
          return FuzzyPoint.new(country_centre["lat"],country_centre["lon"],:country)
        end
      end

      FuzzyPoint.new(0,0,:planet)
    end

    def self.new_from_ip(ip_address)
      #remote_location = Geogov.remote_location(ip_address)
      new()
      # do |gs|
      #  if remote_location
      #    gs.country = remote_location['country']
      #  end
      #  gs.fuzzy_point = gs.calculate_fuzzy_point
      # end
    end

    def self.new_from_hash(hash)
      new() do |gs|
        gs.set_fields(hash)
        unless hash['fuzzy_point']
          raise ArgumentError, "fuzzy point required"
        end
      end
    end

    def to_hash
      {
        :fuzzy_point => self.fuzzy_point.to_hash,
        :postcode => self.postcode,
        :ward => self.ward,
        :council => self.council,
        :nation => self.nation,
        :country => self.country,
        :wmc => self.wmc,
        :friendly_name => self.friendly_name
      }.select {|k,v| !(v.nil?) }
    end

    def update(hash)
      self.class.new() do |empty|
        full_postcode = hash['postcode']
        empty.set_fields(hash)
        if has_valid_lat_lon(hash)
          empty.fetch_missing_fields_for_coords(hash['lat'], hash['lon'])
        elsif full_postcode
          empty.fetch_missing_fields_for_postcode(full_postcode)
        end
        empty.fuzzy_point = empty.calculate_fuzzy_point
      end
    end

    def has_valid_lat_lon(hash)
      return (hash['lon'] and hash['lat'] and hash['lon'] != "" and hash['lat'] != "")
    end

    def fetch_missing_fields_for_postcode(postcode)
      if matches = postcode.match(POSTCODE_REGEXP)
        self.country = "UK"
        fields = Geogov.areas_for_stack_from_postcode(postcode)
        if fields
          lat_lon = fields[:point]
          if lat_lon
            self.friendly_name = Geogov.nearest_place_name(lat_lon['lat'],lat_lon['lon'])
          end
          set_fields(fields.select {|k,v| k != :point})
        end
      end
    end
   
    def fetch_missing_fields_for_coords(lat, lon)
      self.friendly_name = Geogov.nearest_place_name(lat, lon)
      fields = Geogov.areas_for_stack_from_coords(lat, lon)
      if ['England', 'Scotland', 'Northern Ireland', 'Wales'].include?(fields[:nation])
        self.country = 'UK'
        set_fields(fields.select {|k,v| k != :point})
      end
    end

    def set_fields(hash)
      hash.each do |geo, value|
        setter = (geo.to_s+"=").to_sym
        if self.respond_to?(setter)
          unless value == ""
            self.send(setter,value)
          end
        else
          raise ArgumentError, "geo type '#{geo}' is not a valid geo type"
        end
      end
      self
    end

    def fuzzy_point=(point)
      if point.is_a?(Hash)
        @fuzzy_point = FuzzyPoint.new(point["lat"],point["lon"],point["accuracy"])
      else
        @fuzzy_point = point
      end
    end

    POSTCODE_REGEXP = /^([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])[ABD-HJLNP-UW-Z]{2}(:?\s+)?$/i
    SECTOR_POSTCODE_REGEXP =  /^([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])(:?\s+)?$/i

    def postcode=(postcode)
      if (matches = (postcode.match(POSTCODE_REGEXP) || postcode.match(SECTOR_POSTCODE_REGEXP)))
        @postcode = matches[1]+" "+matches[2]
      end
    end
  end
end
