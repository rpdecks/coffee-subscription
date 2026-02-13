class Admin::RoastEventsController < Admin::BaseController
  before_action :set_roast_session

  def create
    @roast_event = @roast_session.roast_events.build(roast_event_params)

    if @roast_event.save
      # If this is a DROP event, calculate derived metrics
      if @roast_event.event_type_drop?
        @roast_session.calculate_derived_metrics!
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_roast_session_path(@roast_session) }
        format.json { render json: event_json(@roast_event), status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("event-errors", partial: "admin/roast_events/errors", locals: { errors: @roast_event.errors }) }
        format.html { redirect_to admin_roast_session_path(@roast_session), alert: @roast_event.errors.full_messages.join(", ") }
        format.json { render json: { errors: @roast_event.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_roast_session
    @roast_session = RoastSession.find(params[:roast_session_id])
  end

  def roast_event_params
    params.require(:roast_event).permit(
      :time_seconds, :bean_temp_f, :manifold_wc,
      :air_position, :event_type, :notes
    )
  end

  def event_json(event)
    {
      id: event.id,
      time_seconds: event.time_seconds,
      formatted_time: event.formatted_time,
      bean_temp_f: event.bean_temp_f,
      manifold_wc: event.manifold_wc,
      air_position: event.air_position,
      event_type: event.event_type,
      event_type_display: event.event_type_display,
      notes: event.notes
    }
  end
end
