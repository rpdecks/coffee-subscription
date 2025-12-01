Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Public pages
  root "pages#home"
  get "about", to: "pages#about"
  get "faq", to: "pages#faq"
  get "contact", to: "pages#contact"
  post "contact", to: "pages#create_contact"

  # Products
  resources :products, only: [:index, :show]

  # Subscription flow (public)
  get "subscribe", to: "subscriptions#landing", as: :subscribe
  get "subscribe/plans", to: "subscriptions#plans", as: :subscription_plans
  get "subscribe/customize/:plan_id", to: "subscriptions#customize", as: :customize_subscription
  post "subscribe/checkout", to: "subscriptions#checkout", as: :subscription_checkout

  # User dashboard (authenticated)
  authenticate :user do
    get "dashboard", to: "dashboard#index", as: :dashboard_root
    
    namespace :dashboard do
      resources :addresses
      resources :payment_methods, only: [:index, :new, :create, :destroy]
      resources :subscriptions, only: [:show, :edit, :update] do
        member do
          post :pause
          post :resume
          delete :cancel
          post :skip_delivery
        end
      end
      resource :coffee_preference, only: [:show, :edit, :update]
      resources :orders, only: [:index, :show]
      resource :profile, only: [:edit, :update]
    end
  end

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :orders do
      member do
        patch :update_status
      end
    end
    resources :subscriptions, only: [:index, :show, :edit, :update] do
      member do
        post :pause
        post :resume
        delete :cancel
      end
    end
    resources :customers, only: [:index, :show]
    resources :products
    resources :subscription_plans
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
