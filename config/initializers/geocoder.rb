# config/initializers/geocoder.rb
# Dynamic provider selection:
# - TEST: always stub (for CI/specs)
# - DEV: real provider by default; optional OFFLINE stub
# - PROD: real provider

if Rails.env.test?
  Geocoder.configure(lookup: :test, units: :mi)
  Geocoder::Lookup::Test.set_default_stub([])
elsif Rails.env.development?
  if ENV["OFFLINE"] == "1" || ENV["GEOCODER_PROVIDER"] == "test"
    Geocoder.configure(lookup: :test, units: :mi)
    Geocoder::Lookup::Test.set_default_stub([]) # no hard-coded cities
  else
    # Dynamic: use Nominatim (OSM). Respect their policy and set a UA/contact.
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
  # Production: use Google if key present, else Nominatim
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

