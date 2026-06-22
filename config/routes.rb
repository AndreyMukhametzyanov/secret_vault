Rails.application.routes.draw do
  root "secrets#new"
  
  resources :secrets, only: [:new, :create, :show] do
    member do
      get :success
      post :reveal
    end
  end
end
