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
    DBService.release_db_connections

    @end_products[vbms_id] ||=
      MetricsService.record("BGS: get end products for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "claim.find_by_vbms_file_number") do
        client.claims.find_by_vbms_file_number(vbms_id.strip)
      end
  end

  def fetch_veteran_info(vbms_id)
    DBService.release_db_connections

    @veteran_info[vbms_id] ||=
      MetricsService.record("BGS: fetch veteran info for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "veteran.find_by_file_number") do
        client.veteran.find_by_file_number(vbms_id)
      end
  end

  def fetch_file_number_by_ssn(ssn)
    DBService.release_db_connections

    @people_by_ssn[ssn] ||=
      MetricsService.record("BGS: fetch person by ssn: #{ssn}",
                            service: :bgs,
                            name: "people.find_by_ssn") do
        client.people.find_by_ssn(ssn)
      end

    @people_by_ssn[ssn] && @people_by_ssn[ssn][:file_nbr]
  end

  def fetch_poa_by_file_number(file_number)
    DBService.release_db_connections

    unless @poas[file_number]
      bgs_poa = MetricsService.record("BGS: fetch poa for file number: #{file_number}",
                                      service: :bgs,
                                      name: "org.find_poas_by_file_number") do
        client.org.find_poas_by_file_number(file_number)
      end
      @poas[file_number] = get_poa_from_bgs_poa(bgs_poa[:power_of_attorney])
    end

    @poas[file_number]
  end

  def fetch_poas_by_participant_id(participant_id)
    DBService.release_db_connections

    unless @poas[participant_id]
      bgs_poas = MetricsService.record("BGS: fetch poas for participant id: #{participant_id}",
                                       service: :bgs,
                                       name: "org.find_poas_by_participant_id") do
        client.org.find_poas_by_ptcpnt_id(participant_id)
      end
      @poas[participant_id] = bgs_poas.map { |poa| get_poa_from_bgs_poa(poa) }
    end

    @poas[participant_id]
  end

  def find_address_by_participant_id(participant_id)
    DBService.release_db_connections

    unless @poa_addresses[participant_id]
      bgs_address = MetricsService.record("BGS: fetch address by participant_id: #{participant_id}",
                                          service: :bgs,
                                          name: "address.find_by_participant_id") do
        client.address.find_all_by_participant_id(participant_id)
      end
      if bgs_address
        # Count on addresses being sorted with most recent first if we return a list of addresses.
        bgs_address = bgs_address[0] if bgs_address.is_a?(Array)
        @poa_addresses[participant_id] = get_address_from_bgs_address(bgs_address)
      end
    end

    @poa_addresses[participant_id]
  end

  # This method checks to see if the current user has access to this case
  # in BGS. Cases in BGS are assigned a "sensitivity level" which may be
  # higher than that of the current employee
  def can_access?(vbms_id)
    current_user = RequestStore[:current_user]
    cache_key = "bgs_can_access_#{current_user.css_id}_#{current_user.station_id}_#{vbms_id}"
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      DBService.release_db_connections

      MetricsService.record("BGS: can_access? (find_by_file_number): #{vbms_id}",
                            service: :bgs,
                            name: "can_access?") do
        client.can_access?(vbms_id, FeatureToggle.enabled?(:can_access_v2, user: current_user))
      end
    end
  end

  def fetch_ratings_in_range(participant_id:, start_date:, end_date:)
    DBService.release_db_connections

    MetricsService.record("BGS: fetch ratings in range: \
                           participant_id = #{participant_id}, \
                           start_date = #{start_date} \
                           end_date = #{end_date}",
                          service: :bgs,
                          name: "rating.find_by_participant_id_and_date_range") do
      client.rating.find_by_participant_id_and_date_range(participant_id, start_date, end_date)
    end
  end

  def fetch_rating_profile(participant_id:, profile_date:)
    DBService.release_db_connections

    MetricsService.record("BGS: fetch rating profile: \
                           participant_id = #{participant_id}, \
                           profile_date = #{profile_date}",
                          service: :bgs,
                          name: "rating_profile.find") do
      client.rating_profile.find(participant_id: participant_id, profile_date: profile_date)
    end
  end

  def fetch_claimant_info_by_participant_id(participant_id)
    DBService.release_db_connections

    MetricsService.record("BGS: fetch claimant info: \
                           participant_id = #{participant_id}",
                          service: :bgs,
                          name: "claimants.find_general_information_by_participant_id") do
      basic_info = client.claimants.find_general_information_by_participant_id(participant_id)
      get_name_and_address_from_bgs_info(basic_info)
    end
  end

  def find_all_relationships(participant_id:)
    DBService.release_db_connections

    MetricsService.record("BGS: find all relationships: \
                           participant_id = #{participant_id}",
                          service: :bgs,
                          name: "claimants.find_all_relationships") do
      client.claimants.find_all_relationships(participant_id) || []
    end
  end

  def get_participant_id_for_user(user)
    DBService.release_db_connections

    MetricsService.record("BGS: find participant id for user #{user.css_id}, #{user.station_id}",
                          service: :bgs,
                          name: "security.find_participant_id") do
      client.security.find_participant_id(css_id: user.css_id, station_id: user.station_id)
    end
  end

  private

  def init_client
    # Fetch current_user from global thread
    current_user = RequestStore[:current_user]

    forward_proxy_url = FeatureToggle.enabled?(:bgs_forward_proxy) ? ENV["RUBY_BGS_PROXY_BASE_URL"] : nil

    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: Rails.application.secrets.user_ip_address,
      client_station_id: current_user.station_id,
      client_username: current_user.css_id,
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      forward_proxy_url: forward_proxy_url,
      log: true
    )
  end
  # :nocov:
end
