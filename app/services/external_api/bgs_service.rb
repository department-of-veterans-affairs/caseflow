require "bgs"

# Thin interface to all things BGS
class ExternalApi::BGSService
  # :nocov:

  ep_codes = %w(
    170APPACT
    170APPACTPMC
    170PGAMC
    170RMD
    170RMDAMC
    170RMDPMC
    172GRANT
    172BVAG
    172BVAGPMC
    400CORRC
    400CORRCPMC
    930RC
    930RCPMC
  )

  def get_eps(vbms_id)
    vbms_id.strip!
    veteran_id = vbms_id[0...-1].rjust(8, '0')
    begin
      bgs.claims.find_by_vbms_file_number(veteran_id)
        .select { |claim| ep_codes.include? claim[:claim_type_code] }
    rescue => e
      puts "Problem loading case #{veteran_id}"
      puts e
    end
  end

  def client
    @client ||= init_client
  end

  private

  def init_client
    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: user.ip_address,
      client_station_id: user.station_id,
      client_username: user.css_id,
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      log: true
    )
  end
  # :nocov:
end
