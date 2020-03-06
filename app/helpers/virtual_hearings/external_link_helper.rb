# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails.

module VirtualHearings::ExternalLinkHelper
  def external_link(url)
    "<a href='#{url}'>#{url}</a>".html_safe
  end

  def phone_link(area_code, prefix, line_number)
    text = "#{area_code}-#{prefix}-#{line_number}"
    "<a href='tel:+1#{area_code}#{prefix}#{line_number}'>#{text}</a>".html_safe
  end
end
