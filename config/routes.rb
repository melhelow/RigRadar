# config/routes.rb
Rails.application.routes.draw do
  devise_for :drivers

  # App
  resources :loads do
    member do
      get   :plan
      patch :start
      patch :deliver
      patch :drop
    end
  end
  resources :rest_areas,     only: [:index, :show]
  resources :weigh_stations, only: [:index, :show]

  # Public pages
  get "about", to: "pages#about"

  # Landing is always root
  root "pages#home"
end
