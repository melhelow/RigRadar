# config/routes.rb
Rails.application.routes.draw do
  get "truck_stops/index"
  get "truck_stops/show"
  get "weigh_stations/index"
  get "weigh_stations/show"
  get "rest_areas/index"
  get "rest_areas/show"
  devise_for :drivers

  # App
  resources :loads do
    member do
      get   :plan
      patch :start
      patch :deliver
      patch :drop
      patch :regeocode 
      post   :add_stops 
      delete :remove_stop
    end
    get :plan, on: :member
  end
  resources :rest_areas,     only: [:index, :show]
  resources :weigh_stations, only: [:index, :show]
  resources :truck_stops,     only: [:index, :show]

  # Public pages
  get "about", to: "pages#about"

  # Landing is always root
  root "pages#home"
end
