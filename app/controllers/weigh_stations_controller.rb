class WeighStationsController < ApplicationController
  before_action :authenticate_driver!

  def index
    @q = params[:q].to_s.strip
    scope = WeighStation.order(state: :asc, name: :asc)
    if @q.present?
      scope = scope.where("state ILIKE ? OR name ILIKE ?", "%#{@q}%", "%#{@q}%")
    end
    @weigh_stations = scope.limit(200)
  end

  def show
    @weigh_station = WeighStation.find(params[:id])
  end
end
