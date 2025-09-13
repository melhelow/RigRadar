
Rails.application.routes.draw do
  get "truck_stops/index"
  get "truck_stops/show"
  get "weigh_stations/index"
  get "weigh_stations/show"
  get "rest_areas/index"
  get "rest_areas/show"
  devise_for :drivers


  resources :loads do
    member do
      get   :preplan
      get   :plan, action: :preplan
      post  :add_stops
      delete :remove_stop
      post :start
      post :deliver
      post :drop
      post :regeocode
    end
  end
  resources :rest_areas,     only: [ :index, :show ]
  resources :weigh_stations, only: [ :index, :show ]
  resources :truck_stops,     only: [ :index, :show ]


  get "about", to: "pages#about"


  root "pages#home"
end
