Rails.application.routes.draw do
  devise_for :drivers

  authenticated :driver do
    root "pages#home", as: :authenticated_root   # later we’ll switch to loads#index
  end

  unauthenticated do
    root "pages#home", as: :unauthenticated_root
  end

  root "pages#home"  # fallback so root_path helper exists
end

