if Rails.env.development? || Rails.env.test?
  Geocoder.configure(lookup: :test, units: :mi)

  Geocoder::Lookup::Test.add_stub("Des Moines, IA", [{ "coordinates" => [41.5868, -93.6250] }])
  Geocoder::Lookup::Test.add_stub("Des Moines, IA, USA", [{ "coordinates" => [41.5868, -93.6250] }])

  Geocoder::Lookup::Test.add_stub("Chicago, IL", [{ "coordinates" => [41.8781, -87.6298] }])
  Geocoder::Lookup::Test.add_stub("Chicago, IL, USA", [{ "coordinates" => [41.8781, -87.6298] }])

  # If a query isn't stubbed, return no results
  Geocoder::Lookup::Test.set_default_stub([])
else
  Geocoder.configure(
    timeout: 5,
    lookup: :nominatim,
    units: :mi,
    http_headers: { "User-Agent" => "RigRadar/1.0 (contact: you@example.com)" }
  )
end
