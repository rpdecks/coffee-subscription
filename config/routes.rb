Rails.application.routes.draw do
  get "/favicon.ico", to: redirect("/icon.png")

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations"
  }

  # Public pages
  root "pages#home"
  get "about", to: "pages#about"
  get "gear", to: "pages#gear", as: :gear
  get "faq", to: "pages#faq"
  get "contact", to: "pages#contact"
  get "thank-you", to: "pages#thank_you"
  get "newsletter/thanks", to: "pages#newsletter_thanks", as: :newsletter_thanks
  post "newsletter/subscribe", to: "newsletter_subscriptions#create", as: :newsletter_subscribe
  post "contact", to: "pages#create_contact"

  # Products
  resources :products, only: [ :index, :show ]

  # Shop - One-time purchases
  get "shop", to: "shop#index", as: :shop
  get "shop/products/:id", to: "shop#show", as: :shop_product
  get "shop/checkout", to: "shop#checkout", as: :shop_checkout
  post "shop/checkout/session", to: "shop#create_checkout_session", as: :shop_create_checkout
  get "shop/success", to: "shop#success", as: :shop_success
  post "shop/cart/add", to: "shop#add_to_cart", as: :shop_add_to_cart
  delete "shop/cart/remove/:product_id", to: "shop#remove_from_cart", as: :shop_remove_from_cart
  patch "shop/cart/update/:product_id", to: "shop#update_cart", as: :shop_update_cart
  delete "shop/cart/clear", to: "shop#clear_cart", as: :shop_clear_cart

  # Subscription flow (public)
  get "subscribe", to: "subscriptions#landing", as: :subscribe
  get "subscribe/plans", to: "subscriptions#plans", as: :subscription_plans
  get "subscribe/customize/:plan_id", to: "subscriptions#customize", as: :customize_subscription
  post "subscribe/checkout", to: "subscriptions#checkout", as: :subscription_checkout
  get "subscribe/success", to: "subscriptions#success", as: :subscription_success

  # Stripe webhooks
  post "webhooks/stripe", to: "webhooks#stripe"

  # User dashboard (authenticated)
  authenticate :user do
    get "dashboard", to: "dashboard#index", as: :dashboard_root

    namespace :dashboard do
      resources :addresses
      resources :payment_methods, only: [ :index, :new, :create, :destroy ] do
        member do
          post :set_default
        end
      end
      resources :subscriptions, only: [ :show, :edit, :update ] do
        member do
          post :pause
          post :resume
          delete :cancel
          post :skip_delivery
          patch :update_address
        end
      end
      resource :coffee_preference, only: [ :show, :edit, :update ]
      resources :orders, only: [ :index, :show ]
      resource :profile, only: [ :edit, :update ]
    end
  end

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :orders do
      collection do
        get :export
      end
      member do
        patch :update_status
      end
    end
    resources :subscriptions, only: [ :index, :show, :edit, :update ] do
      member do
        patch :pause
        patch :resume
        patch :cancel
      end
    end
    resources :customers, only: [ :index, :show ] do
      collection do
        get :export
      end
    end
    resources :products do
      member do
        patch :toggle_active
        patch :toggle_shop_visibility
      end

      delete "images/:attachment_id", to: "products#destroy_image", as: :destroy_image
      patch "images/:attachment_id/feature", to: "products#make_featured_image", as: :make_featured_image
    end
    resources :subscription_plans do
      member do
        patch :toggle_active
      end
    end
    resources :inventory, except: [ :show ]
    resource :production_plan, only: [ :show ]
    resources :roasted_inventories, only: [ :new, :create ]
  end

  # Email testing (admin only, development)
  get "email_tests", to: "email_tests#index"
  post "email_tests/send", to: "email_tests#send_test_email", as: :send_test_email

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
