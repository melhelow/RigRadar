# config/routes.rb
Rails.application.routes.draw do
  # Devise routes (using default controllers & app/views/devise/*)
  devise_for :drivers

  # Auth-aware roots (for now both go to landing page)
  authenticated :driver do
    root "pages#home", as: :authenticated_root
  end

  unauthenticated do
    root "pages#home", as: :unauthenticated_root
  end

  # Fallback so `root_path` always exists in views/layouts
  root "pages#home"

end
