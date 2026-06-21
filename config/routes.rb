Rails.application.routes.draw do
  root "secrets#new"
  
  resources :secrets, only: [:new, :create, :show] do
    member do
      get :success
    end
  end
end
