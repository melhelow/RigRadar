class TruckStopsController < ApplicationController
  def index
    @providers = [
      "Love's", "Pilot", "Flying J", "TA", "Petro", "AMBEST", "Pilot Flying J"
    ]

    scope = TruckStop.all

    if params[:q].present?
      q = "%#{params[:q].strip}%"
      scope = scope.where(
        "name ILIKE :q OR city ILIKE :q OR state ILIKE :q",
        q: q
      )
    end

    if params[:providers].present?
      scope = scope.where(provider: params[:providers])
    end

    min_parking = params[:min_parking].to_i
    scope = scope.where("parking_truck >= ?", min_parking) if min_parking > 0

    @truck_stops = scope.order(:state, :city, :name).limit(200)
  end

  def show
  end
end
