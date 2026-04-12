Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :workflows
      post "events", to: "events#create"
    end
  end
end