# config/initializers/dev_db_guard.rb
ActiveSupport.on_load(:active_record) do
  # Only protect local dev & test. Production is untouched.
  next unless Rails.env.development? || Rails.env.test?

  cfg  = ActiveRecord::Base.connection_db_config
  host = cfg.respond_to?(:configuration_hash) ? cfg.configuration_hash[:host] : nil

  if host&.include?("sql.xata.sh")
    abort "\n🚫 Refusing to connect to Xata in #{Rails.env}. " \
          "Unset DATABASE_URL to use your local DB.\n"
  end
end
