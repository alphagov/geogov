module Geogov

class FuzzyPoint
  ACCURACIES = [:point,:postcode,:postcode_district,:ward,:council,:nation,:country,:planet]
  attr_reader :lon, :lat, :accuracy


  def initialize(lat,lon,accuracy)
    accuracy = accuracy.to_sym
    raise ValueError unless ACCURACIES.include?(accuracy)
    @lon,@lat,@accuracy = lon.to_f, lat.to_f, accuracy
    if @accuracy == :point
      @lon = @lon.round(2)
      @lat = @lat.round(2)
    end
  end

  def to_hash
    {"lon"=> self.lon.to_s,"lat"=>self.lat.to_s,"accuracy"=>accuracy.to_s}
  end
end

end
