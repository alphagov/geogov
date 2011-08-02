module Geogov
  class DracosGazetteer 
      def initialize(default_url = "http://gazetteer.dracos.vm.bytemark.co.uk")
          @base = default_url
      end

      def nearest_place_name(lat,lon)
        url = "#{@base}/point/#{lat},#{lon}.json"
        results = Geogov.get_json(url)
        if results && results["place"]
          return results["place"][0]
        else
          return nil
        end
      end
     

  end
end
