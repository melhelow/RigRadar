class LoadsController < ApplicationController
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
    ts_box = TruckStop.where(latitude: min_lat..max_lat, longitude: min_lon..max_lon)

    @rest_areas_on_route = ra_box.select { |r|
      lat = r.public_send(ra_lat); lon = r.public_send(ra_lon)
      lat && lon && corridor.include_point?(lat, lon)
    }

    @weigh_stations_on_route = ws_box.select { |w|
      lat = w.public_send(ws_lat); lon = w.public_send(ws_lon)
      lat && lon && corridor.include_point?(lat, lon)
    }

    @truck_stops_on_route = ts_box.select { |t|
      t.latitude && t.longitude && corridor.include_point?(t.latitude, t.longitude)
    }

    @buffer = buffer

    render :plan 
  end



def add_stops
  selections = Array(params[:selected] || params[:stops])

  added = 0
  selections.each do |token|
   
    type, raw_id = token.to_s.split("-", 2)
    next unless %w[TruckStop RestArea WeighStation].include?(type) && raw_id.to_i.positive?

    model = type.constantize
    stop  = model.find_by(id: raw_id)
    next unless stop

    
    @load.load_stops.find_or_create_by!(stoppable: stop)
    added += 1
  end

  redirect_to @load, notice: "#{added} #{'stop'.pluralize(added)} added to this load."
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
