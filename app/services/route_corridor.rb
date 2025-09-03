# app/services/route_corridor.rb
# frozen_string_literal: true

class RouteCorridor
  LAT_MI_PER_DEG = 69.0

  def initialize(a_lat, a_lon, b_lat, b_lon, buffer_miles: 15)
    @a = [a_lat.to_f, a_lon.to_f]
    @b = [b_lat.to_f, b_lon.to_f]
    @buffer = buffer_miles.to_f
    @mid_lat = ((@a[0] + @b[0]) / 2.0).to_f
    @lon_mi_per_deg = (69.172 * Math.cos(@mid_lat * Math::PI / 180.0)).abs
    @lon_mi_per_deg = 1.0 if @lon_mi_per_deg.zero?
  end

  def bbox_with_padding
    min_lat, max_lat = [@a[0], @b[0]].minmax
    min_lon, max_lon = [@a[1], @b[1]].minmax
    lat_pad = @buffer / LAT_MI_PER_DEG
    lon_pad = @buffer / @lon_mi_per_deg
    [min_lat - lat_pad, max_lat + lat_pad, min_lon - lon_pad, max_lon + lon_pad]
  end

  def include_point?(lat, lon)
    p = [lat.to_f, lon.to_f]
    return false unless in_bbox?(p)
    distance_point_to_segment_miles(p, @a, @b) <= @buffer
  end

  private

  def in_bbox?(p)
    min_lat, max_lat, min_lon, max_lon = bbox_with_padding
    p[0].between?(min_lat, max_lat) && p[1].between?(min_lon, max_lon)
  end

  def distance_point_to_segment_miles(p, a, b)
    to_xy = ->(lat, lon) { [lon * @lon_mi_per_deg, lat * LAT_MI_PER_DEG] }
    px, py = to_xy.call(*p); ax, ay = to_xy.call(*a); bx, by = to_xy.call(*b)
    abx, aby = bx - ax, by - ay
    apx, apy = px - ax, py - ay
    ab_len2 = abx * abx + aby * aby
    t = if ab_len2.zero?
      0.0
    else
      v = (apx * abx + apy * aby) / ab_len2
      [[v, 0.0].max, 1.0].min
    end
    cx, cy = ax + t * abx, ay + t * aby
    Math.hypot(px - cx, py - cy)
  end
end
