# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShopController, type: :controller do
  let(:user) { create(:customer_user) }
  let!(:product1) { create(:product, name: "Ethiopian Yirgacheffe", price_cents: 1800, active: true, visible_in_shop: true, product_type: :coffee, inventory_count: 10) }
  let!(:product2) { create(:product, name: "Colombian Supremo", price_cents: 1600, active: true, visible_in_shop: true, product_type: :coffee, inventory_count: 5) }
  let!(:merch_product) { create(:product, name: "Coffee Mug", price_cents: 1200, active: true, visible_in_shop: true, product_type: :merch, inventory_count: 20) }
  let!(:hidden_product) { create(:product, name: "Hidden Product", active: true, visible_in_shop: false, inventory_count: 10) }
  let!(:inactive_product) { create(:product, active: false) }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns active, visible, in-stock products (all categories)' do
      get :index
      expect(assigns(:products)).to match_array([ product1, product2, merch_product ])
      expect(assigns(:products)).not_to include(inactive_product)
      expect(assigns(:products)).not_to include(hidden_product)
    end

    it 'filters by coffee category' do
      get :index, params: { category: 'coffee' }
      expect(assigns(:products)).to match_array([ product1, product2 ])
      expect(assigns(:products)).not_to include(merch_product)
    end

    it 'filters by merch category' do
      get :index, params: { category: 'merch' }
      expect(assigns(:products)).to match_array([ merch_product ])
      expect(assigns(:products)).not_to include(product1)
      expect(assigns(:products)).not_to include(product2)
    end

    it 'does not require authentication' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a success response for active, visible product' do
      get :show, params: { id: product1.id }
      expect(response).to be_successful
    end

    it 'assigns the requested product' do
      get :show, params: { id: product1.id }
      expect(assigns(:product)).to eq(product1)
    end

    it 'redirects for inactive product' do
      get :show, params: { id: inactive_product.id }
      expect(response).to redirect_to(shop_path)
    end

    it 'redirects for hidden product' do
      get :show, params: { id: hidden_product.id }
      expect(response).to redirect_to(shop_path)
    end
  end

  describe 'GET #checkout' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :checkout
        expect(response).to redirect_to(new_user_session_path)
      end

      # Note: store_location_for is called but controller specs don't properly
      # persist the Devise session storage in a way that's testable via session hash
    end

    context "when user is authenticated" do
      before { sign_in user, scope: :user }

      context 'with empty cart' do
        it 'redirects to shop' do
          get :checkout
          expect(response).to redirect_to(shop_path)
          expect(flash[:alert]).to eq('Your cart is empty')
        end
      end

      context 'with items in cart' do
        before do
          session[:cart] = [
            { 'product_id' => product1.id.to_s, 'quantity' => '2' },
            { 'product_id' => product2.id.to_s, 'quantity' => '1' }
          ]
        end

        it 'returns a success response' do
          get :checkout
          expect(response).to be_successful
        end

        it 'loads products with quantities' do
          get :checkout
          products_with_quantities = assigns(:products_with_quantities)

          expect(products_with_quantities.length).to eq(2)
          expect(products_with_quantities[0][:product]).to eq(product1)
          expect(products_with_quantities[0][:quantity]).to eq(2)
        end

        it 'calculates totals' do
          get :checkout
          expect(assigns(:subtotal)).to eq(52.0) # (18 * 2) + (16 * 1)
          expect(assigns(:shipping)).to eq(5.0)
          expect(assigns(:total)).to eq(57.0)
        end
      end
    end
  end

  describe 'POST #create_checkout_session' do
    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        post :create_checkout_session, params: { cart_items: [] }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user, scope: :user }

      context 'with empty cart' do
        it 'returns unprocessable entity' do
          post :create_checkout_session, params: { cart_items: [] }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Cart is empty')
        end
      end

      context 'with valid cart items' do
        let(:cart_items) do
          [
            { product_id: product1.id, quantity: 2 },
            { product_id: product2.id, quantity: 1 }
          ]
        end
        let(:stripe_session) { double('Stripe::Checkout::Session', url: 'https://checkout.stripe.com/test') }

        before do
          allow(StripeService).to receive(:create_product_checkout_session).and_return(stripe_session)
        end

        it 'creates a Stripe checkout session' do
          expect(StripeService).to receive(:create_product_checkout_session).with(
            hash_including(
              user: user,
              success_url: shop_success_url,
              cancel_url: shop_checkout_url
            )
          )

          post :create_checkout_session, params: { cart_items: cart_items }
        end

        it 'returns the checkout URL' do
          post :create_checkout_session, params: { cart_items: cart_items }

          expect(response).to be_successful
          expect(JSON.parse(response.body)['checkout_url']).to eq('https://checkout.stripe.com/test')
        end
      end

      context 'when Stripe service fails' do
        let(:cart_items) { [ { product_id: product1.id, quantity: 1 } ] }

        before do
          allow(StripeService).to receive(:create_product_checkout_session)
            .and_raise(StripeService::StripeError.new('API Error'))
        end

        it 'returns unprocessable entity with error message' do
          post :create_checkout_session, params: { cart_items: cart_items }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq('Unable to create checkout session')
        end
      end
    end
  end

  describe 'GET #success' do
    before { sign_in user, scope: :user }

    it 'returns a success response' do
      get :success
      expect(response).to be_successful
    end

    it 'loads the most recent one-time order' do
      order = create(:order, user: user, order_type: :one_time)
      get :success
      expect(assigns(:order)).to eq(order)
    end
  end

  describe 'POST #add_to_cart' do
    it 'adds product to cart' do
      post :add_to_cart, params: { product_id: product1.id, quantity: 2 }

      expect(session[:cart]).to include({ 'product_id' => product1.id.to_s, 'quantity' => '2' })
      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to include(product1.name)
    end

    it 'updates quantity if product already in cart' do
      session[:cart] = [ { 'product_id' => product1.id.to_s, 'quantity' => '1' } ]

      post :add_to_cart, params: { product_id: product1.id, quantity: 2 }

      cart_item = session[:cart].find { |item| item['product_id'] == product1.id.to_s }
      expect(cart_item['quantity']).to eq('3')
    end

    it 'defaults to quantity 1 if not specified' do
      post :add_to_cart, params: { product_id: product1.id }

      cart_item = session[:cart].find { |item| item['product_id'] == product1.id.to_s }
      expect(cart_item['quantity']).to eq('1')
    end

    it 'redirects for inactive product' do
      post :add_to_cart, params: { product_id: inactive_product.id }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to eq('Product not available')
    end
  end

  describe 'DELETE #remove_from_cart' do
    before do
      session[:cart] = [
        { 'product_id' => product1.id.to_s, 'quantity' => '2' },
        { 'product_id' => product2.id.to_s, 'quantity' => '1' }
      ]
    end

    it 'removes product from cart' do
      delete :remove_from_cart, params: { product_id: product1.id }

      expect(session[:cart]).not_to include(hash_including('product_id' => product1.id.to_s))
      expect(session[:cart]).to include(hash_including('product_id' => product2.id.to_s))
      expect(response).to redirect_to(shop_checkout_path)
    end
  end

  describe 'PATCH #update_cart' do
    before do
      session[:cart] = [ { 'product_id' => product1.id.to_s, 'quantity' => '2' } ]
    end

    it 'updates quantity' do
      patch :update_cart, params: { product_id: product1.id, quantity: 5 }

      cart_item = session[:cart].find { |item| item['product_id'] == product1.id.to_s }
      expect(cart_item['quantity']).to eq('5')
    end

    it 'removes item if quantity is 0' do
      patch :update_cart, params: { product_id: product1.id, quantity: 0 }

      expect(session[:cart]).to be_empty
    end

    it 'redirects to checkout' do
      patch :update_cart, params: { product_id: product1.id, quantity: 3 }
      expect(response).to redirect_to(shop_checkout_path)
    end
  end

  describe 'DELETE #clear_cart' do
    before do
      session[:cart] = [
        { 'product_id' => product1.id.to_s, 'quantity' => '2' },
        { 'product_id' => product2.id.to_s, 'quantity' => '1' }
      ]
    end

    it 'clears all items from cart' do
      delete :clear_cart

      expect(session[:cart]).to be_empty
      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to eq('Cart cleared')
    end
  end
end
