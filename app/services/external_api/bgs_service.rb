require "bgs"

# Thin interface to all things BGS
class ExternalApi::BGSService
  attr_accessor :client

  def initialize
    @client = init_client

    # These instance variables are used for caching their
    # respective requests
    @end_products = {}
    @veteran_info = {}
  end

  # :nocov:

  def get_end_products(vbms_id)
    @end_products[vbms_id] ||=
      MetricsService.timer("BGS: get end products for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "claim.find_by_vbms_file_number") do
        client.claims.find_by_vbms_file_number(vbms_id.strip)
      end
  end

  def fetch_veteran_info(vbms_id)
    @veteran_info[vbms_id] ||=
      MetricsService.timer("BGS: fetch veteran info for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "veteran.find_by_file_number") do
        client.veteran.find_by_file_number(vbms_id)
      end
  end

  private

  def init_client
    # Fetch current_user from global thread
    current_user = RequestStore[:current_user]

    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: current_user.ip_address,
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
