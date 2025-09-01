Rails.application.routes.draw do
  devise_for :drivers

  resources :loads do
    member do
      get   :plan      # separate page (GET) for route planning
      patch :start     # state change → redirect
      patch :deliver
      patch :drop
    end
  end

  resources :rest_areas,     only: [:index, :show]    # browse pages (added in Step 7)
  resources :weigh_stations, only: [:index, :show]

  authenticated :driver do
    root "loads#index", as: :authenticated_root
  end
  unauthenticated do
    root "pages#home", as: :unauthenticated_root
  end
  root "pages#home"  # fallback
end

