require "bgs"

# Thin interface to all things BGS
class ExternalApi::BGSService
  # :nocov:

  def get_end_products(vbms_id)
    client.claims.find_by_vbms_file_number(vbms_id.strip)
  end

  def client
    @client ||= init_client
  end

  private

  def init_client
    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: request.remote_ip,
      client_station_id: current_user.station_id,
      client_username: current_user.css_id,
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      log: true
    )
  end
  # :nocov:
end
