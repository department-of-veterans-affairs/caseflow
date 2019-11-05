# frozen_string_literal: true

module VirtualHearings::PexipClient
  def client
    @client ||= PexipService.new(
      host: ENV["PEXIP_API_HOST"],
      port: ENV["PEXIP_API_PORT"],
      user_name: ENV["PEXIP_API_USERNANME"],
      password: ENV["PEXIP_API_PASSWORD"],
      client_host: ENV["PEXIP_API_CLIENT"]
    )
  end
end
