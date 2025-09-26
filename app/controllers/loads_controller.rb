class LoadsController < ApplicationController
  # NOTE: The controllers are a bit too large. As a convention, it's best to keep controllers "skinny" by moving all business logic into the corresponding model or a Rails Concern. Also, please ensure the code formatting is consistent.
   require "set"
  before_action :authenticate_driver!

  before_action :set_load, only: [ :show, :edit, :update, :destroy, :start, :deliver, :drop, :plan, :preplan, :regeocode, :add_stops, :remove_stop ]

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
    @loads = policy_scope(Load).order(created_at: :desc)
    authorize Load
  end

def show
  @load = current_driver.loads.find(params[:id])
  @selected_stops = @load.load_stops.includes(:stoppable).order(:created_at)

  # build weigh stations for the map + read-only list
  buffer = params[:buffer].presence.to_i
  buffer = 15 if buffer <= 0 || buffer > 50
  @buffer = buffer

  if @load.pickup_lat && @load.pickup_lon && @load.dropoff_lat && @load.dropoff_lon
    corridor = RouteCorridor.new(
      @load.pickup_lat,  @load.pickup_lon,
      @load.dropoff_lat, @load.dropoff_lon,
      buffer_miles: buffer
    )
    min_lat, max_lat, min_lon, max_lon = corridor.bbox_with_padding

    ws_lat = WeighStation.column_names.include?("lat") ? :lat : :latitude
    ws_lon = WeighStation.column_names.include?("lon") ? :lon : :longitude

    ws_box = WeighStation.where(ws_lat => min_lat..max_lat, ws_lon => min_lon..max_lon)
    @weigh_stations_on_route = ws_box.select do |ws|
      lat = ws.public_send(ws_lat)
      lon = ws.public_send(ws_lon)
      lat && lon && corridor.include_point?(lat, lon)
    end
  else
    @weigh_stations_on_route = []
  end
end



  def new
    @load = current_driver.loads.new
    authorize @load
  end

  def create
    @load = current_driver.loads.new(load_params)
    authorize @load
    if @load.save
      redirect_to @load, notice: "Load created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # NOTE: No authorize on edit, so will that mean anyone is allowed to edit? 
end

  def update
    if @load.update(load_params)
      redirect_to @load, notice: "Load updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # NOTE: No authorize on destroy, so will that mean anyone is allowed to destroy as well? 
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

  pickup_coords  = [ @load.pickup_lat,  @load.pickup_lon ]
  dropoff_coords = [ @load.dropoff_lat, @load.dropoff_lon ]


  ra_lat = RestArea.column_names.include?("lat") ? :lat : :latitude
  ra_lon = RestArea.column_names.include?("lon") ? :lon : :longitude
  ws_lat = WeighStation.column_names.include?("lat") ? :lat : :latitude
  ws_lon = WeighStation.column_names.include?("lon") ? :lon : :longitude

  ra_box = RestArea.where(ra_lat => min_lat..max_lat, ra_lon => min_lon..max_lon)
  ws_box = WeighStation.where(ws_lat => min_lat..max_lat, ws_lon => min_lon..max_lon)


  ts_scope = TruckStop.where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)


  if providers_n.any?
    ts_scope = ts_scope.where("LOWER(TRIM(provider)) IN (?)", providers_n)
  end


  if min_parking
    ts_scope = ts_scope.where("COALESCE(parking_truck, 0) >= ?", min_parking)
  end

  @rest_areas_on_route = ra_box.filter_map do |rest_area|
  lat = rest_area.public_send(ra_lat)
  lon = rest_area.public_send(ra_lon)
  next unless lat && lon
  next unless corridor.include_point?(lat, lon)

  miles_from_pickup = Geocoder::Calculations.distance_between(pickup_coords, [ lat, lon ], units: :mi)
  miles_to_dropoff  = Geocoder::Calculations.distance_between([ lat, lon ], dropoff_coords, units: :mi)

  rest_area.define_singleton_method(:miles_from_pickup) { miles_from_pickup }
  rest_area.define_singleton_method(:miles_to_dropoff)  { miles_to_dropoff }
  rest_area
end


  @weigh_stations_on_route = ws_box.filter_map do |weigh_station|
  lat = weigh_station.public_send(ws_lat)
  lon = weigh_station.public_send(ws_lon)
  next unless lat && lon
  next unless corridor.include_point?(lat, lon)

  miles_from_pickup = Geocoder::Calculations.distance_between(pickup_coords, [ lat, lon ], units: :mi)
  miles_to_dropoff  = Geocoder::Calculations.distance_between([ lat, lon ], dropoff_coords, units: :mi)

  weigh_station.define_singleton_method(:miles_from_pickup) { miles_from_pickup }
  weigh_station.define_singleton_method(:miles_to_dropoff)  { miles_to_dropoff }
  weigh_station
end


  @truck_stops_on_route =
  ts_scope.filter_map do |truck_stop|
    next unless truck_stop.latitude && truck_stop.longitude
    next unless corridor.include_point?(truck_stop.latitude, truck_stop.longitude)

    miles_from_pickup = Geocoder::Calculations.distance_between(
      pickup_coords, [ truck_stop.latitude, truck_stop.longitude ], units: :mi
    )
    miles_to_dropoff = Geocoder::Calculations.distance_between(
      [ truck_stop.latitude, truck_stop.longitude ], dropoff_coords, units: :mi
    )


    truck_stop.define_singleton_method(:miles_from_pickup) { miles_from_pickup }
    truck_stop.define_singleton_method(:miles_to_dropoff)  { miles_to_dropoff }
    truck_stop
  end


@truck_stops_on_route.sort_by!(&:miles_from_pickup)


  @buffer       = buffer
  @providers    = providers
  @min_parking  = min_parking
  @selected_stop_keys =
    @load.load_stops.pluck(:stoppable_type, :stoppable_id).map { |t, id| "#{t}-#{id}" }

  render :plan
end




def add_stops
  chosen_tokens = Array(params[:selected] || params[:stops]).map(&:to_s)
  # Ignore weigh stations – they’re auto-included/read-only
  chosen_tokens.reject! { |tok| tok.start_with?("WeighStation-") }

  parsed = chosen_tokens.filter_map do |tok|
    if (m = tok.match(/\A(TruckStop|RestArea|WeighStation)-(\d+)\z/))
      [ m[1], m[2].to_i ]
    end
  end

  desired = parsed.to_set
  added = removed = 0

  LoadStop.transaction do
    existing = @load.load_stops.pluck(:id, :stoppable_type, :stoppable_id)
    existing_pairs = existing.map { |(_id, type, sid)| [ type, sid ] }.to_set

    to_remove_ids = existing.select { |id, type, sid| !desired.include?([ type, sid ]) }.map(&:first)
    removed = @load.load_stops.where(id: to_remove_ids).delete_all

    (desired - existing_pairs).each do |(type, stoppable_id)|
      @load.load_stops.create!(stoppable_type: type, stoppable_id: stoppable_id)
      added += 1
    end
  end

  redirect_to load_path(@load, anchor: "map"),
              notice: "#{added} added, #{removed} removed. Saved your pre-plan."

# --- Auto-attach weigh stations on the current corridor ---
buffer = params[:buffer].to_i
buffer = 15 if buffer <= 0 || buffer > 50

if @load.pickup_lat && @load.pickup_lon && @load.dropoff_lat && @load.dropoff_lon
  corridor = RouteCorridor.new(
    @load.pickup_lat,  @load.pickup_lon,
    @load.dropoff_lat, @load.dropoff_lon,
    buffer_miles: buffer
  )
  min_lat, max_lat, min_lon, max_lon = corridor.bbox_with_padding

  ws_lat = WeighStation.column_names.include?("lat") ? :lat : :latitude
  ws_lon = WeighStation.column_names.include?("lon") ? :lon : :longitude

  ws_candidates = WeighStation.where(ws_lat => min_lat..max_lat, ws_lon => min_lon..max_lon)
  ws_on_route = ws_candidates.select do |weigh_station|
    lat = weigh_station.public_send(ws_lat)
    lon = weigh_station.public_send(ws_lon)
    lat && lon && corridor.include_point?(lat, lon)
  end

  ws_on_route.each do |weigh_station|
    @load.load_stops.find_or_create_by!(stoppable: weigh_station)
  end
end
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
    authorize @load
  end
  def load_params
    params.require(:load).permit(:commodity, :weight_lbs, :pickup_location, :dropoff_location, :deadline)
  end
end
