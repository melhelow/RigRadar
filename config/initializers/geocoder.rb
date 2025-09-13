

if Rails.env.test?
  Geocoder.configure(lookup: :test, units: :mi)
  Geocoder::Lookup::Test.set_default_stub([])
elsif Rails.env.development?
  if ENV["OFFLINE"] == "1" || ENV["GEOCODER_PROVIDER"] == "test"
    Geocoder.configure(lookup: :test, units: :mi)
    Geocoder::Lookup::Test.set_default_stub([]) 
  else
    
    Geocoder.configure(
      lookup: :nominatim,
      timeout: 5,
      units: :mi,
      http_headers: { "User-Agent" => "RigRadar Dev (contact: you@example.com)" },
      cache: Rails.cache,
      cache_prefix: "geocoder:"
    )
  end
else

  if ENV["GOOGLE_MAPS_API_KEY"].present?
    Geocoder.configure(
      lookup: :google,
      api_key: ENV["GOOGLE_MAPS_API_KEY"],
      timeout: 5,
      units: :mi,
      cache: Rails.cache,
      cache_prefix: "geocoder:"
    )
  else
    Geocoder.configure(
      lookup: :nominatim,
      timeout: 5,
      units: :mi,
      http_headers: { "User-Agent" => "RigRadar Prod (contact: you@example.com)" },
      cache: Rails.cache,
      cache_prefix: "geocoder:"
    )
  end
end
