Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :secrets, only: [ :new, :create, :show ] do
    member do
      get :success
      post :reveal
    end
  end

  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms
  get "/security", to: "pages#security", as: :security
end
