require "bgs"

# Thin interface to all things BGS
class ExternalApi::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  attr_accessor :client

  def initialize
    @client = init_client

    # These instance variables are used for caching their
    # respective requests
    @end_products = {}
    @veteran_info = {}
    @poas = {}
    @poa_addresses = {}
    @people_by_ssn = {}
  end

  # :nocov:

  def get_end_products(vbms_id)
    @end_products[vbms_id] ||=
      MetricsService.record("BGS: get end products for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "claim.find_by_vbms_file_number") do
        client.claims.find_by_vbms_file_number(vbms_id.strip)
      end
  end

  def fetch_veteran_info(vbms_id)
    @veteran_info[vbms_id] ||=
      MetricsService.record("BGS: fetch veteran info for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "veteran.find_by_file_number") do
        client.veteran.find_by_file_number(vbms_id)
      end
  end

  def fetch_file_number_by_ssn(ssn)
    @people_by_ssn[ssn] ||=
      MetricsService.record("BGS: fetch person by ssn: #{ssn}",
                            service: :bgs,
                            name: "people.find_by_ssn") do
        client.people.find_by_ssn(ssn)
      end

    @people_by_ssn[ssn] && @people_by_ssn[ssn][:file_nbr]
  end

  def fetch_poa_by_file_number(file_number)
    unless @poas[file_number]
      bgs_poa = MetricsService.record("BGS: fetch veteran info for file number: #{file_number}",
                                      service: :bgs,
                                      name: "org.find_poas_by_file_number") do
        client.org.find_poas_by_file_number(file_number)
      end
      @poas[file_number] = get_poa_from_bgs_poa(bgs_poa)
    end

    @poas[file_number]
  end

  def find_address_by_participant_id(participant_id)
    unless @poa_addresses[participant_id]
      bgs_address = MetricsService.record("BGS: fetch address by participant_id: #{participant_id}",
                                          service: :bgs,
                                          name: "address.find_by_participant_id") do
        client.address.find_all_by_participant_id(participant_id)
      end
      if bgs_address
        @poa_addresses[participant_id] = get_address_from_bgs_address(bgs_address)
      end
    end

    @poa_addresses[participant_id]
  end

  # This method checks to see if the current user has access to this case
  # in BGS. Cases in BGS are assigned a "sensitivity level" which may be
  # higher than that of the current employee
  def can_access?(vbms_id)
    MetricsService.record("BGS: can_access? (find_flashes): #{vbms_id}",
                          service: :bgs,
                          name: "can_access?") do
      client.can_access?(vbms_id)
    end
  end

  private

  def init_client
    # Fetch current_user from global thread
    current_user = RequestStore[:current_user]

    # This is here to make sure StartCertificationJob
    # can pass the ip address to the BGS client.
    # We should find a better way to do this.
    ip_address = current_user.ip_address || RequestStore[:ip_address]

    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: ip_address,
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
