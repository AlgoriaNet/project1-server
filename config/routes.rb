Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "test" => "test#index"

  # Defines the root path route ("/")
  # root "posts#index"
  post "/api/login" => "sessions#login", as: :rails_login
  post "/api/guest_login" => "users#guest_login", as: :guest_login
  
  namespace :api do
    get "/allies", to: "allies#index"
    get "/allies/:ally_id/upgrade_levels", to: "allies#upgrade_levels"
    get "/gem-levels", to: "allies#gem_levels"
    get "/level_up_costs", to: "allies#level_up_costs"
    
    # Static Data System
    get "/static_data/manifest", to: "static_data#manifest"
    get "/static_data/bundle/:bundle_name", to: "static_data#bundle"
  end

  # Direct file serving for static data (what frontend actually expects)
  get "/static_data/version.json" => "static_data#version_file"
  get "/static_data/skill_effects.json" => "static_data#skill_effects_file"

  mount ActionCable.server => '/cable'
end
