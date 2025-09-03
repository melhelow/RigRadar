# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # send users to Loads after *either* sign-in or sign-up
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || loads_path
  end

  # optional: after sign-out, go back to landing
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
