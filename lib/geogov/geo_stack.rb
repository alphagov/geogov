module Geogov
  class GeoStack

    attr_accessor :ward, :council, :nation, :country, :region, :lat, :lon, :authorities, :fuzzy_point
    attr_reader :postcode

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
      remote_location = Geogov.remote_location(ip_address)
      new() do |gs|
        if remote_location
          gs.country = remote_location['country']
        end
        gs.fuzzy_point = gs.calculate_fuzzy_point
      end
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
        :council => self.council,
        :ward => self.ward,
        :friendly_name => self.friendly_name,
        :nation => self.nation
      }
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

    def friendly_name
      @friendly_name ||= build_locality
    end

    def get_authority(type)
      authorities[type.upcase.to_sym]
    end

    def formatted_authority_name(type)
      authority = get_authority(type) or return type

      authority["name"].
        sub(/ *((District Council|Borough Council|Community|County Council|City Council|Council) ?)+/,'').
        sub(/ (North|East|South|West|Central)$/,'').
        sub(/Mid /,'')
    end

    LOCALITY_TRANSLATION = {
      %w[ DIS CTY ] => %w[ DIS CTY ],
      %w[ LBO ]     => %w[ LBO London ],
      %w[ UTA CPC ] => %w[ CPC UTA ], # for cornwall civil parishes
      %w[ UTA UTE ] => %w[ UTE UTA ],
      %w[ UTA UTW ] => %w[ UTW UTA ],
      %w[ MTW MTD ] => %w[ MTW MTD ]
    }

    def build_locality
      return false unless authorities

      LOCALITY_TRANSLATION.each do |matches, locality|
        if matches.all? { |a| get_authority(a) }
          return locality.map { |a| formatted_authority_name(a) }.uniq.join(", ")
        end
      end

      false
    end

    def has_valid_lat_lon(hash)
      %w[ lat lon ].none? { |k| hash[k].to_s.empty? }
    end

    def fetch_missing_fields_for_postcode(postcode)
      if matches = postcode.match(POSTCODE_REGEXP)
        self.country = "UK"
        fields = Geogov.areas_for_stack_from_postcode(postcode)
        if fields
          lat_lon = fields[:point]
          set_fields(fields.select {|k,v| k != :point})
        end
      end
    end

    def fetch_missing_fields_for_coords(lat, lon)
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
          self.authorities ||= { }
          self.authorities[geo] = value
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
