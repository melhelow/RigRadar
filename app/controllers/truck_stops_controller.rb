class TruckStopsController < ApplicationController
  before_action :authenticate_driver!

  def index
    @providers = [
      "Love's", "Pilot", "Flying J", "TA", "Petro", "AMBEST", "Pilot Flying J"
    ]

    scope = TruckStop.all

    # ---- Text search --------------------------------------------------------
    if params[:q].present?
      q = params[:q].strip

      # Handle "City, ST" specifically (e.g., "Gary, IN")
      if (m = q.match(/\A(.+?),\s*([A-Za-z]{2})\z/))
        city  = m[1].strip
        state = m[2].upcase
        scope = scope.where("city ILIKE ? AND state ILIKE ?", "%#{city}%", "%#{state}%")
      else
        # Tokenize by comma/space; require each token to hit name OR city OR state
        tokens = q.split(/[,\s]+/).reject(&:blank?)
        tokens.each do |tok|
          pat = "%#{tok}%"
          scope = scope.where("name ILIKE ? OR city ILIKE ? OR state ILIKE ?", pat, pat, pat)
        end
      end
    end

    # ---- Provider filter (case/space-insensitive) --------------------------
    if params[:providers].present?
      normalized = Array(params[:providers]).reject(&:blank?).map { |p| p.downcase.strip }
      scope = scope.where("LOWER(TRIM(provider)) IN (?)", normalized) if normalized.any?
    end

    # ---- Min truck parking (treat NULL as 0) -------------------------------
    if params[:min_parking].present?
      n = params[:min_parking].to_i
      scope = scope.where("COALESCE(parking_truck, 0) >= ?", n)
    end

    @truck_stops = scope.order(:state, :city, :name).limit(200)
  end

  def show
    @truck_stop = TruckStop.find(params[:id])
  end
end
