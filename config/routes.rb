Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :ingredients, only: :index do
        collection { get :popular }
      end
      get "recipes/search", to: "recipes#search"
      resources :recipes, only: :show
    end
  end

  get "*path", to: "spa#index", constraints: ->(req) { !req.path.start_with?("/api", "/up") }
end
