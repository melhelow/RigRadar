class RestAreasController < ApplicationController
  before_action :authenticate_driver!

  def index
    @q = params[:q].to_s.strip
    scope = RestArea.order(state: :asc, highway_route: :asc, mile_post: :asc)
    if @q.present?
      # very simple filter: match state code or highway string
      scope = scope.where("state ILIKE ? OR highway_route ILIKE ?", "%#{@q}%", "%#{@q}%")
    end
    @rest_areas = scope.limit(200)
  end

  def show
    @rest_area = RestArea.find(params[:id])
  end
end
