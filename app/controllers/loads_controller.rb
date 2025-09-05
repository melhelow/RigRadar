class LoadsController < ApplicationController
   require "set"
  before_action :authenticate_driver!
 
  before_action :set_load, only: [:show, :edit, :update, :destroy, :start, :deliver, :drop, :plan,:preplan, :regeocode, :add_stops, :remove_stop]

  def regeocode
    @load.pickup_location_will_change!
    @load.dropoff_location_will_change!
    if @load.save
      redirect_to plan_load_path(@load), notice: "Coordinates refreshed."
    else
      redirect_to @load, alert: "Could not refresh coordinates."
    end
  end


  def index
    @loads = current_driver.loads.order(created_at: :desc)
  end

  def show
    @load = current_driver.loads.find(params[:id])
    @selected_stops = @load.load_stops.includes(:stoppable).order(:created_at)
  end



  def new
    @load = current_driver.loads.new
  end

  def create
    @load = current_driver.loads.new(load_params)
    if @load.save
      redirect_to @load, notice: "Load created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @load.update(load_params)
      redirect_to @load, notice: "Load updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @load.destroy
    redirect_to loads_path, notice: "Load deleted."
  end

  
  def start
    @load.update!(status: :in_transit, started_at: Time.current)
    redirect_to @load, notice: "Load started."
  end

  def deliver
    @load.update!(status: :delivered)
    redirect_to @load, notice: "Load delivered."
  end

  def drop
    @load.update!(status: :dropped)
    redirect_to @load, notice: "Load dropped."
  end

def preplan
  if @load.pickup_lat.blank? || @load.pickup_lon.blank? ||
     @load.dropoff_lat.blank? || @load.dropoff_lon.blank?
    redirect_to @load, alert: "Missing coordinates. Edit the load locations and save again." and return
  end

  buffer = params[:buffer].presence.to_i
  buffer = 15 if buffer <= 0 || buffer > 50

  # read filters
  providers   = Array(params[:providers]).reject(&:blank?)
  providers_n = providers.map { |p| p.to_s.downcase.strip } # normalized
  min_parking = params[:min_parking].presence&.to_i
  min_parking = nil if min_parking && min_parking <= 0

  corridor = RouteCorridor.new(
    @load.pickup_lat,  @load.pickup_lon,
    @load.dropoff_lat, @load.dropoff_lon,
    buffer_miles: buffer
  )
  min_lat, max_lat, min_lon, max_lon = corridor.bbox_with_padding

  ra_lat = RestArea.column_names.include?("lat") ? :lat : :latitude
  ra_lon = RestArea.column_names.include?("lon") ? :lon : :longitude
  ws_lat = WeighStation.column_names.include?("lat") ? :lat : :latitude
  ws_lon = WeighStation.column_names.include?("lon") ? :lon : :longitude

  ra_box = RestArea.where(ra_lat => min_lat..max_lat, ra_lon => min_lon..max_lon)
  ws_box = WeighStation.where(ws_lat => min_lat..max_lat, ws_lon => min_lon..max_lon)

  # base scope inside corridor bbox
  ts_scope = TruckStop.where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)

  # provider filter (case/space-insensitive)
  if providers_n.any?
    ts_scope = ts_scope.where("LOWER(TRIM(provider)) IN (?)", providers_n)
  end

  # parking filter (treat nil as 0 so it gets excluded when min_parking present)
  if min_parking
    ts_scope = ts_scope.where("COALESCE(parking_truck, 0) >= ?", min_parking)
  end

  @rest_areas_on_route = ra_box.select do |r|
    lat = r.public_send(ra_lat); lon = r.public_send(ra_lon)
    lat && lon && corridor.include_point?(lat, lon)
  end

  @weigh_stations_on_route = ws_box.select do |w|
    lat = w.public_send(ws_lat); lon = w.public_send(ws_lon)
    lat && lon && corridor.include_point?(lat, lon)
  end

  @truck_stops_on_route = ts_scope.select do |t|
    t.latitude && t.longitude && corridor.include_point?(t.latitude, t.longitude)
  end

  @buffer       = buffer
  @providers    = providers            # echo back to view
  @min_parking  = min_parking
  @selected_stop_keys =
    @load.load_stops.pluck(:stoppable_type, :stoppable_id).map { |t,id| "#{t}-#{id}" }

  render :plan
end




def add_stops
  
  chosen_tokens = Array(params[:selected] || params[:stops]).map(&:to_s)

  
  parsed = chosen_tokens.filter_map do |tok|
    if (m = tok.match(/\A(TruckStop|RestArea|WeighStation)-(\d+)\z/))
      [m[1], m[2].to_i] # [type, id]
    end
  end

  desired = parsed.to_set

  added = removed = 0
  LoadStop.transaction do
    
    existing = @load.load_stops.pluck(:id, :stoppable_type, :stoppable_id)
    existing_pairs = existing.map { |(_id, t, sid)| [t, sid] }.to_set

    
    to_remove_ids = existing.
      select { |id, t, sid| !desired.include?([t, sid]) }.
      map(&:first)

    removed = @load.load_stops.where(id: to_remove_ids).delete_all

    
    (desired - existing_pairs).each do |(type, sid)|
      @load.load_stops.create!(stoppable_type: type, stoppable_id: sid)
      added += 1
    end
  end

  redirect_to load_path(@load, anchor: "map"),
              notice: "#{added} added, #{removed} removed. Saved your pre-plan."
end


def remove_stop
  ls = @load.load_stops.find_by(id: params[:stop_id])
  if ls
    ls.destroy
    redirect_to @load, notice: "Stop removed from this load."
  else
    redirect_to @load, alert: "Stop not found."
  end
end


  private
  def set_load
    @load = current_driver.loads.find(params[:id])
  end
  def load_params
    params.require(:load).permit(:commodity, :weight_lbs, :pickup_location, :dropoff_location, :deadline)
  end
end
