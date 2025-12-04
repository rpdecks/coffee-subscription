module Dashboard
  class SubscriptionsController < DashboardController
    before_action :set_subscription, only: [:show, :edit, :update, :pause, :resume, :cancel, :skip_delivery]

    def show
      @next_order = @subscription.orders.where('created_at >= ?', @subscription.next_delivery_date).first
    end

    def edit
    end

    def update
      if @subscription.update(subscription_params)
        redirect_to dashboard_subscription_path(@subscription), notice: "Subscription updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def pause
      if @subscription.active?
        begin
          # Pause in Stripe
          if @subscription.stripe_subscription_id.present?
            StripeService.pause_subscription(@subscription.stripe_subscription_id)
          end
          
          @subscription.update(status: :paused)
          # SubscriptionMailer.subscription_paused(@subscription).deliver_later
          redirect_to dashboard_subscription_path(@subscription), notice: "Your subscription has been paused. No charges or deliveries will occur until you resume."
        rescue StripeService::StripeError => e
          redirect_to dashboard_subscription_path(@subscription), alert: "Unable to pause subscription: #{e.message}"
        end
      else
        redirect_to dashboard_subscription_path(@subscription), alert: "Subscription cannot be paused."
      end
    end

    def resume
      if @subscription.paused?
        begin
          # Resume in Stripe
          if @subscription.stripe_subscription_id.present?
            StripeService.resume_subscription(@subscription.stripe_subscription_id)
          end
          
          @subscription.update(status: :active, next_delivery_date: calculate_next_delivery_date)
          # SubscriptionMailer.subscription_resumed(@subscription).deliver_later
          redirect_to dashboard_subscription_path(@subscription), notice: "Your subscription has been resumed. Next delivery: #{@subscription.next_delivery_date.strftime('%B %d, %Y')}."
        rescue StripeService::StripeError => e
          redirect_to dashboard_subscription_path(@subscription), alert: "Unable to resume subscription: #{e.message}"
        end
      else
        redirect_to dashboard_subscription_path(@subscription), alert: "Subscription cannot be resumed."
      end
    end

    def cancel
      if @subscription.active? || @subscription.paused?
        begin
          # Cancel in Stripe (at period end to allow finishing current billing cycle)
          if @subscription.stripe_subscription_id.present?
            StripeService.cancel_subscription(@subscription.stripe_subscription_id, cancel_at_period_end: true)
          end
          
          @subscription.update(status: :cancelled, cancelled_at: Time.current)
          # SubscriptionMailer.subscription_cancelled(@subscription).deliver_later
          redirect_to dashboard_root_path, notice: "Your subscription will be cancelled at the end of the current billing period. You can still enjoy your coffee until then!"
        rescue StripeService::StripeError => e
          redirect_to dashboard_subscription_path(@subscription), alert: "Unable to cancel subscription: #{e.message}"
        end
      else
        redirect_to dashboard_subscription_path(@subscription), alert: "Subscription cannot be cancelled."
      end
    end

    def skip_delivery
      if @subscription.active?
        frequency_days = case @subscription.subscription_plan.frequency
                        when 'weekly' then 7
                        when 'biweekly' then 14
                        when 'monthly' then 30
                        end
        
        new_delivery_date = @subscription.next_delivery_date + frequency_days.days
        @subscription.update(next_delivery_date: new_delivery_date)
        
        redirect_to dashboard_subscription_path(@subscription), notice: "Next delivery skipped. Your new delivery date is #{new_delivery_date.strftime('%B %d, %Y')}."
      else
        redirect_to dashboard_subscription_path(@subscription), alert: "Cannot skip delivery for inactive subscription."
      end
    end

    private

    def set_subscription
      @subscription = current_user.subscriptions.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_root_path, alert: "Subscription not found."
    end

    def subscription_params
      params.require(:subscription).permit(
        :subscription_plan_id,
        :shipping_address_id,
        :payment_method_id,
        :bag_size,
        :quantity
      )
    end

    def calculate_next_delivery_date
      frequency_days = case @subscription.subscription_plan.frequency
                      when 'weekly' then 7
                      when 'biweekly' then 14
                      when 'monthly' then 30
                      end
      
      Date.today + frequency_days.days
    end
  end
end
