Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :workflows
      resources :execution_logs, only: [:index]
      post "events", to: "events#create"
    end
  end
end