class WhatsNewController < ApplicationController
  def show
    cookies[:whats_new] = { value: WhatsNewService.version, expires_in: 1.year.from_now }
    @show_whats_new_indicator = false
  end
end
