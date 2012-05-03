module Geogov
  class GeoStack

    attr_accessor :ward, :council, :nation, :country, :region, :lat, :lon, :authorities, :fuzzy_point
    attr_reader :postcode

    def initialize(&block)
      if block_given?
        yield self
        raise ArgumentError, "fuzzy point required" unless fuzzy_point
      else
        self.fuzzy_point = calculate_fuzzy_point
      end
    end

    def calculate_fuzzy_point
      if lat && lon
        return FuzzyPoint.new(lat, lon, :point)
      end

      if postcode
        district = postcode.split(" ")[0]
        district_centre = Geogov.centre_of_district(district)
        if district_centre
          return FuzzyPoint.new(district_centre["lat"], district_centre["lon"],:postcode_district)
        end
      end

      if country
        country_centre = Geogov.centre_of_country(country)
        if country_centre
          return FuzzyPoint.new(country_centre["lat"], country_centre["lon"],:country)
        end
      end

      FuzzyPoint.new(0,0,:planet)
    end

    def self.new_from_ip(ip_address)
      remote_location = Geogov.remote_location(ip_address)
      new { |gs|
        gs.country = remote_location['country'] if remote_location
        gs.fuzzy_point = gs.calculate_fuzzy_point
      }
    end

    def self.new_from_hash(hash)
      new { |gs| gs.set_fields hash }
    end

    def to_hash
      {
        :fuzzy_point   => fuzzy_point.to_hash,
        :postcode      => postcode,
        :council       => council,
        :ward          => ward,
        :friendly_name => friendly_name,
        :nation        => nation
      }
    end

    def update(hash)
      self.class.new do |empty|
        full_postcode = hash['postcode']
        empty.set_fields hash
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

      authority["name"].gsub(%r{
        \s*((((District|Borough|County|City)\s|)Council|Community)\s?)+ |
        \s(North|East|South|West|Central)$ |
        Mid\s
      }x, "")
    end

    # Key to the three-letter abbreviations
    # CTY | County
    # CED | County Electoral Division
    # DIS | District
    # DIW | District Ward
    # EUR | European Region
    # GLA | Greater London Authority
    # LAC | Greater London Authority Assembly Constituency
    # LBR | London Borough
    # LBW | London Borough Ward
    # MTD | Metropolitan District
    # MTW | Metropolitan District Ward
    # SPE | Scottish Parliament Electoral Region
    # SPC | Scottish Parliament Constituency
    # UTA | Unitary Authority
    # UTE | Unitary Authority Electoral Division
    # UTW | Unitary Authority Ward
    # WAE | Welsh Assembly Electoral Region
    # WAC | Welsh Assembly Constituency
    # WMC | Westminster Constituency
    # LGW | NI Ward
    # LGD | NI Council
    # LGE | NI Electoral Area
    # NIE | NI Assembly Constituency
    # NIA | NI Assembly

    LOCALITY_KEYS = [
      [:LBO],       # London (special case)
      [:DIS, :CTY],
      [:CPC, :UTA], # Cornwall civil parishes
      [:UTE, :UTA],
      [:UTW, :UTA],
      [:MTW, :MTD],
      [:LGW, :LGD]
    ]

    def build_locality
      return false unless authorities
      selected_keys = LOCALITY_KEYS.find { |t|
        (t - authorities.keys).none?
      } or return false

      parts = selected_keys.map { |a| formatted_authority_name(a) }
      parts << "London" if selected_keys == [:LBO]
      parts.uniq.join(", ")
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
          set_fields fields.select { |k,v| k != :point }
        end
      end
    end

    UK_NATIONS = ['England', 'Scotland', 'Northern Ireland', 'Wales']

    def fetch_missing_fields_for_coords(lat, lon)
      fields = Geogov.areas_for_stack_from_coords(lat, lon)
      if UK_NATIONS.include?(fields[:nation])
        self.country = 'UK'
        set_fields fields.select { |k,v| k != :point }
      end
    end

    def set_fields(hash)
      hash.each do |geo, value|
        setter = "#{geo.to_s}=".to_sym
        if respond_to?(setter)
          self.send(setter, value) unless value == ""
        else
          self.authorities ||= {}
          self.authorities[geo] = value
        end
      end
      self
    end

    def fuzzy_point=(point)
      if point.is_a?(Hash)
        @fuzzy_point = FuzzyPoint.new(point["lat"], point["lon"], point["accuracy"])
      else
        @fuzzy_point = point
      end
    end

    POSTCODE_REGEXP = /^([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])[ABD-HJLNP-UW-Z]{2}(:?\s+)?$/i
    SECTOR_POSTCODE_REGEXP =  /^([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])(:?\s+)?$/i

    def postcode=(postcode)
      if (matches = (postcode.match(POSTCODE_REGEXP) || postcode.match(SECTOR_POSTCODE_REGEXP)))
        @postcode = [matches[1], matches[2]].join(" ")
      end
    end
  end
end
