Rails.application.routes.draw do
  devise_for :drivers

  # TEMP while Loads controller doesn't exist yet
  authenticated :driver do
    root "pages#home", as: :authenticated_root
  end
  unauthenticated do
    root "pages#home", as: :unauthenticated_root
  end
end
