class LoadsController < ApplicationController
  before_action :authenticate_driver!
  before_action :set_load, only: [:show, :edit, :update, :destroy, :start, :deliver, :drop, :plan]
  before_action :set_load, only: [:show, :edit, :update, :destroy, :start, :deliver, :drop, :plan, :regeocode]
# ...
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

  def show; end

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


def plan
  unless @load.pickup_lat && @load.pickup_lon && @load.dropoff_lat && @load.dropoff_lon
    redirect_to @load, alert: "Missing coordinates. Edit the load locations and save again." and return
  end

  buffer = params[:buffer].presence.to_i
  buffer = 15 if buffer <= 0 || buffer > 50

  corridor = ::RouteCorridor.new(
    @load.pickup_lat,  @load.pickup_lon,
    @load.dropoff_lat, @load.dropoff_lon,
    buffer_miles: buffer
  )
  min_lat, max_lat, min_lon, max_lon = corridor.bbox_with_padding
  ts_box = TruckStop.where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)

  if params[:providers].present?
  ts_box = ts_box.where(provider: params[:providers])
end

min_parking = params[:min_parking].to_i
if min_parking > 0
  ts_box = ts_box.where("parking_truck >= ?", min_parking)
end

@truck_stops_on_route = ts_box.select do |t|
  t.latitude && t.longitude && corridor.include_point?(t.latitude, t.longitude)
end

if @truck_stops_on_route.any? && corridor.respond_to?(:progress_miles)
  @truck_stops_on_route.sort_by! { |t| corridor.progress_miles(t.latitude, t.longitude) }
end

  # --- Dynamic column detection (handles lat/lon vs latitude/longitude) ---
  ra_lat_col = RestArea.column_names.include?("lat") ? :lat : :latitude
  ra_lon_col = RestArea.column_names.include?("lon") ? :lon : :longitude

  ws_lat_col = WeighStation.column_names.include?("lat") ? :lat : :latitude
  ws_lon_col = WeighStation.column_names.include?("lon") ? :lon : :longitude

  # 1) Coarse filter by bounding box in SQL
  ra_box = RestArea.where(ra_lat_col => min_lat..max_lat, ra_lon_col => min_lon..max_lon)
  ws_box = WeighStation.where(ws_lat_col => min_lat..max_lat, ws_lon_col => min_lon..max_lon)

  # 2) Precise filter by distance-to-segment in Ruby
  @rest_areas_on_route = ra_box.select do |r|
    lat = r.public_send(ra_lat_col)
    lon = r.public_send(ra_lon_col)
    lat && lon && corridor.include_point?(lat, lon)
  end

  @weigh_stations_on_route = ws_box.select do |w|
    lat = w.public_send(ws_lat_col)
    lon = w.public_send(ws_lon_col)
    lat && lon && corridor.include_point?(lat, lon)
  end

  @buffer = buffer
end
  
def regeocode
  @load = current_driver.loads.find(params[:id])
  @load.pickup_location_will_change!
  @load.dropoff_location_will_change!
  if @load.save
    redirect_to plan_load_path(@load), notice: "Coordinates refreshed."
  else
    redirect_to @load, alert: "Could not refresh coordinates."
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
