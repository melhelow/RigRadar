module ApplicationHelper

  def provider_badge(provider)
  return "" if provider.blank?
  color =
    case provider
    when "Love's" then "#eab308"
    when "Pilot", "Pilot Flying J" then "#ef4444"
    when "Flying J" then "#f97316"
    when "TA" then "#3b82f6"
    when "Petro" then "#10b981"
    when "AMBEST" then "#8b5cf6"
    else "#6b7280"
    end
  %Q(<span style="display:inline-block;padding:.1rem .4rem;border-radius:.4rem;background:#{color};color:white;font-size:.75rem;">#{ERB::Util.h(provider)}</span>).html_safe
end

end
