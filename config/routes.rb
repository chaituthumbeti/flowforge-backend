Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :workflows, only: [:index, :create, :show, :update, :destroy] do
        member do
          get :parse
          post :run
        end
      end

      resources :execution_logs, only: [:index]
      post "events", to: "events#create"
    end
  end
end 