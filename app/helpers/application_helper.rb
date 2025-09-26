module ApplicationHelper
  # NOTE: Cool use of a helper
  def provider_badge(provider)
    return "" if provider.blank?
    content_tag :span, provider,
      class: "badge rounded-pill text-bg-light border"
  end
end
