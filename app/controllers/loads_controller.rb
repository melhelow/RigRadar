class LoadsController < ApplicationController
  before_action :authenticate_driver!
  before_action :set_load, only: [:show, :edit, :update, :destroy, :start, :deliver, :drop, :plan]

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

  # state changes (MVP)
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

  # route planning (bonus)
  def plan
    # This action would typically render a view with a map interface.
    # The actual route planning logic would be handled via JavaScript and external APIs.
  end
  private
  def set_load
    @load = current_driver.loads.find(params[:id])
  end
  def load_params
    params.require(:load).permit(:commodity, :weight_lbs, :pickup_location, :dropoff_location, :deadline)
  end
end
