Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
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

  get "/billing", to: "billing#show", as: :billing
  post "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  get "/billing/return", to: "billing#return", as: :billing_return
  patch "/billing/cancel_auto_renew", to: "billing#cancel_auto_renew", as: :billing_cancel_auto_renew

  post "/webhooks/yookassa", to: "webhooks/yookassa#create"
end
