class Admin::RoastSessionsController < Admin::BaseController
  before_action :set_roast_session, only: [ :show, :edit, :update, :destroy, :end_roast ]

  def index
    @roast_sessions = RoastSession.recent
    @pagy, @roast_sessions = pagy(@roast_sessions, items: 20)
  end

  def show
    @roast_events = @roast_session.roast_events.chronological
  end

  def new
    @roast_session = RoastSession.new(
      gas_type: :lp,
      batch_size_g: 450
    )
  end

  def create
    @roast_session = RoastSession.new(roast_session_params)
    @roast_session.started_at = Time.current

    if @roast_session.save
      redirect_to admin_roast_session_path(@roast_session), notice: "Roast started."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @roast_session.update(roast_session_params)
      redirect_to admin_roast_session_path(@roast_session), notice: "Roast session updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @roast_session.destroy
    redirect_to admin_roast_sessions_path, notice: "Roast session deleted."
  end

  def end_roast
    @roast_session.update!(ended_at: Time.current)
    @roast_session.calculate_derived_metrics!
    redirect_to admin_roast_session_path(@roast_session), notice: "Roast ended."
  end

  def export
    @roast_session = RoastSession.find(params[:id])
    events = @roast_session.roast_events.chronological

    csv_data = CSV.generate(headers: true) do |csv|
      csv << RoastEvent.csv_headers
      events.each { |e| csv << e.to_csv_row }
    end

    send_data csv_data,
      filename: "roast_#{@roast_session.id}_#{@roast_session.coffee_name.parameterize}_#{@roast_session.started_at&.strftime('%Y%m%d')}.csv",
      type: "text/csv"
  end

  private

  def set_roast_session
    @roast_session = RoastSession.find(params[:id])
  end

  def roast_session_params
    params.require(:roast_session).permit(
      :coffee_name, :lot_id, :process, :batch_size_g,
      :ambient_temp_f, :charge_temp_target_f, :gas_type,
      :green_weight_g, :roasted_weight_g, :notes
    )
  end
end
