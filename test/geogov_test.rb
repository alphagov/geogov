require 'test_helper'

class GovspeakTest < Test::Unit::TestCase

  test "IP-located stack should have country" do
    Geogov.configure do |g|
      g.provider_for :centre_of_country, stub(:centre_of_country => {"lat"=>37, "lon"=>-96})
      g.provider_for :remote_location, stub(:remote_location => {'country' => 'US'})
    end

    stack = Geogov::GeoStack.new_from_ip('173.203.129.90')
    assert_equal "US", stack.country
    assert_in_delta stack.fuzzy_point.lon, -96, 0.5
    assert_in_delta stack.fuzzy_point.lat, 37, 0.5
    assert_equal :country, stack.fuzzy_point.accuracy
  end

  test "should be specific if no country available" do
    Geogov.configure do |g|
      g.provider_for :remote_location, stub(:remote_location => nil)
    end

    stack = Geogov::GeoStack.new_from_ip('127.0.0.1')
    assert_nil stack.country
    assert_equal 0, stack.fuzzy_point.lon
    assert_equal 0, stack.fuzzy_point.lat
    assert_equal :planet, stack.fuzzy_point.accuracy
  end

  test "raises an exception if provider doesn't support required method" do
    assert_raises(ArgumentError) {
      Geogov.configure do |g|
        g.provider_for :lat_lon_from_postcode, stub
      end
    }
  end

  test "raises an error if the supplied postcode is invalid" do
    assert_raises(Geogov::UnrecognizedLocationError) {
      Geogov.lat_lon_from_postcode("nowhere")
    }
  end

  test "reconstructed stack rejects unknown params" do
    assert_raises(ArgumentError) {
      Geogov::GeoStack.new_from_hash("galaxy" => "Andromeda")
    }
  end

  test "reconstructed stack should refuse creation if no fuzzy point" do
    assert_raises(ArgumentError) {
      Geogov::GeoStack.new_from_hash("country" => "US")
    }
  end

  test "reconstructed stack should always truncate postcode" do
    stack = Geogov::GeoStack.new_from_hash("postcode"=>"SE10 8UG", "country" => "UK", "fuzzy_point" => {"lat"=>"37", "lon"=>"-96", "accuracy"=>"postcode"})
    assert_equal "SE10 8", stack.postcode
  end

  test "stack should not consider a postcode with trailing whitespace invalid" do
    stack = Geogov::GeoStack.new_from_hash("postcode"=>"SE10 8UG ", "country" => "UK", "fuzzy_point" => {"lat"=>"37", "lon"=>"-96", "accuracy"=>"postcode"})
    assert_equal "SE10 8", stack.postcode
  end

  test "stack should ignore invalid postcodes" do
    stack = Geogov::GeoStack.new_from_hash("postcode"=>"NOTAPOSTCODE", "country" => "UK", "fuzzy_point" => {"lat"=>"37", "lon"=>"-96", "accuracy"=>"postcode"})
    assert_nil stack.postcode
  end

  test "stack with country should have country accuracy" do
    stack = Geogov::GeoStack.new_from_hash("country" => "US", "fuzzy_point" => {"lat"=>"37", "lon"=>"-96", "accuracy"=>"country"})
    assert_equal :country, stack.fuzzy_point.accuracy
  end

  test "stack with postcode returns correct locality" do
    stack = Geogov::GeoStack.new
    stack = stack.update('postcode' => "SW1A 1AA")

    assert_equal "Westminster, London", stack.friendly_name
  end

  test "stack with coordinates returns correct locality" do
    stack = Geogov::GeoStack.new
    stack = stack.update('lat' => "51.501009", "lon" => "-0.1415870")

    assert_equal "Westminster, London", stack.friendly_name
  end

  test "stack with postcode returns authorities" do
    stack = Geogov::GeoStack.new
    stack = stack.update('postcode' => "SW1A 1AA")

    assert stack.authorities.any?
  end

  test "stack with coordinates returns authorities" do
    stack = Geogov::GeoStack.new
    stack = stack.update('lat' => "51.501009", "lon" => "-0.1415870")

    assert stack.authorities.any?
  end

  test "stack with postcode returns correct locality, ward and council" do
    stack = Geogov::GeoStack.new
    stack = stack.update('postcode' => "SW1A 1AA")

    assert_equal "Westminster, London", stack.friendly_name
    assert stack.ward and stack.ward.any?
    assert stack.council and stack.council.any?
    assert_equal "Westminster City Council", stack.council.first['name']
  end

  test "stack with coordinates returns correct locality, ward and council" do
    stack = Geogov::GeoStack.new
    stack = stack.update('lat' => "51.501009", "lon" => "-0.1415870")

    assert_equal "Westminster, London", stack.friendly_name
    assert stack.ward and stack.ward.any?
    assert stack.council and stack.council.any?
    assert_equal "Westminster City Council", stack.council.first['name']
  end

end
