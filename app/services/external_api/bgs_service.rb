# frozen_string_literal: true

require "bgs"

# Thin interface to all things BGS
class ExternalApi::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  attr_reader :client

  def initialize(client: init_client)
    @client = client

    # These instance variables are used for caching their
    # respective requests
    @end_products = {}
    @veteran_info = {}
    @person_info = {}
    @poas = {}
    @poa_by_participant_ids = {}
    @addresses = {}
    @people_by_ssn = {}
  end

  # :nocov:

  def get_end_products(vbms_id)
    DBService.release_db_connections

    @end_products[vbms_id] ||=
      MetricsService.record("BGS: get end products for vbms id: #{vbms_id}",
                            service: :bgs,
                            name: "claims.find_by_vbms_file_number") do
        client.claims.find_by_vbms_file_number(vbms_id.strip)
      end
  end

  def cancel_end_product(veteran_file_number, end_product_code, end_product_modifier)
    DBService.release_db_connections

    @end_products[veteran_file_number] ||=
      MetricsService.record("BGS: cancel end product by: \
                            file_number = #{veteran_file_number}, \
                            end_product_code = #{end_product_code}, \
                            modifier = #{end_product_modifier}",
                            service: :bgs,
                            name: "claims.cancel_end_product") do
        client.claims.cancel_end_product(
          file_number: veteran_file_number,
          end_product_code: end_product_code,
          modifier: end_product_modifier
        )
      end
  end

  def fetch_veteran_info(vbms_id)
    DBService.release_db_connections

    @veteran_info[vbms_id] ||=
      Rails.cache.fetch(fetch_veteran_info_cache_key(vbms_id), expires_in: 10.minutes) do
        MetricsService.record("BGS: fetch veteran info for vbms id: #{vbms_id}",
                              service: :bgs,
                              name: "veteran.find_by_file_number") do
          client.veteran.find_by_file_number(vbms_id)
        end
      end
  end

  def fetch_person_info(participant_id)
    DBService.release_db_connections

    bgs_info = MetricsService.record("BGS: fetch person info by participant id: #{participant_id}",
                                     service: :bgs,
                                     name: "people.find_person_by_ptcpnt_id") do
      client.people.find_person_by_ptcpnt_id(participant_id)
    end

    return {} unless bgs_info

    @person_info[participant_id] ||= {
      first_name: bgs_info[:first_nm],
      last_name: bgs_info[:last_nm],
      middle_name: bgs_info[:middle_nm],
      name_suffix: bgs_info[:suffix_nm],
      birth_date: bgs_info[:brthdy_dt],
      email_address: bgs_info[:email_addr]
    }
  end

  def fetch_person_by_ssn(ssn)
    DBService.release_db_connections

    @people_by_ssn[ssn] ||=
      MetricsService.record("BGS: fetch person by ssn: #{ssn}",
                            service: :bgs,
                            name: "people.find_by_ssn") do
        client.people.find_by_ssn(ssn)
      end
    @people_by_ssn[ssn]
  end

  def fetch_file_number_by_ssn(ssn)
    person = fetch_person_by_ssn(ssn)
    person[:file_nbr] if person
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

    unless @poa_by_participant_ids[participant_id]
      bgs_poas = MetricsService.record("BGS: fetch poas for participant id: #{participant_id}",
                                       service: :bgs,
                                       name: "org.find_poas_by_participant_id") do
        client.org.find_poas_by_ptcpnt_id(participant_id)
      end
      @poa_by_participant_ids[participant_id] = [bgs_poas].flatten.compact.map { |poa| get_poa_from_bgs_poa(poa) }
    end

    @poa_by_participant_ids[participant_id]
  end

  def fetch_poas_by_participant_ids(participant_ids)
    DBService.release_db_connections

    bgs_poas = MetricsService.record("BGS: fetch poas for participant ids: #{participant_ids}",
                                     service: :bgs,
                                     name: "org.find_poas_by_participant_ids") do
      client.org.find_poas_by_ptcpnt_ids(participant_ids)
    end

    # Avoid passing nil
    get_hash_of_poa_from_bgs_poas(bgs_poas || [])
  end

  def fetch_limited_poas_by_claim_ids(claim_ids)
    DBService.release_db_connections

    bgs_limited_poas = MetricsService.record("BGS: fetch limited poas for claim ids: #{claim_ids}",
                                             service: :bgs,
                                             name: "org.find_limited_poas_by_bnft_claim_ids") do
      client.org.find_limited_poas_by_bnft_claim_ids(claim_ids)
    end

    get_limited_poas_hash_from_bgs(bgs_limited_poas)
  end

  def find_address_by_participant_id(participant_id)
    finder = ExternalApi::BgsAddressFinder.new(participant_id: participant_id, client: client)
    @addresses[participant_id] ||= finder.mailing_address || finder.addresses.last
  end

  # This method checks to see if the current user has access to this case
  # in BGS. Cases in BGS are assigned a "sensitivity level" which may be
  # higher than that of the current employee.
  #
  # We cache at 2 levels: the boolean check per user, and the veteran record itself.
  # The veteran record is so that subsequent calls to fetch_veteran_info can read from cache.
  def can_access?(vbms_id)
    Rails.cache.fetch(can_access_cache_key(current_user, vbms_id), expires_in: 2.hours) do
      DBService.release_db_connections

      MetricsService.record("BGS: can_access? (find_by_file_number): #{vbms_id}",
                            service: :bgs,
                            name: "can_access?") do
        record = client.veteran.find_by_file_number(vbms_id)
        # local memo cache for this object
        @veteran_info[vbms_id] ||= record
        # persist cache for other objects
        Rails.cache.write(fetch_veteran_info_cache_key(vbms_id), record, expires_in: 10.minutes)
        true
      rescue BGS::ShareError
        false
      end
    end
  end

  # station_conflict? performs a few checks to determine if the current user
  # has a same-station conflict with the veteran in question
  def station_conflict?(vbms_id, veteran_participant_id)
    # sometimes find_flashes works
    begin
      client.claimants.find_flashes(vbms_id)
    rescue BGS::ShareError
      return true
    end

    # sometimes the station conflict logic works
    ExternalApi::BgsVeteranStationUserConflict.new(
      veteran_participant_id: veteran_participant_id,
      client: client
    ).conflict?
  end

  def bust_can_access_cache(user, vbms_id)
    Rails.cache.delete(can_access_cache_key(user, vbms_id))
  end

  def bust_fetch_veteran_info_cache(vbms_id)
    Rails.cache.delete(fetch_veteran_info_cache_key(vbms_id))
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
      bgs_info = client.claimants.find_general_information_by_participant_id(participant_id)
      bgs_info ? { relationship: bgs_info[:payee_type_name], payee_code: bgs_info[:payee_type_code] } : {}
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
    get_participant_id_for_css_id_and_station_id(user.css_id, user.station_id)
  end

  def get_participant_id_for_css_id_and_station_id(css_id, station_id)
    DBService.release_db_connections

    MetricsService.record("BGS: find participant id for user #{css_id}, #{station_id}",
                          service: :bgs,
                          name: "security.find_participant_id") do
      client.security.find_participant_id(css_id: css_id.upcase, station_id: station_id)
    end
  end

  # This method is available to retrieve and validate a letter created with manage_claimant_letter_v2
  def find_claimant_letters(document_id)
    DBService.release_db_connections
    MetricsService.record("BGS: find claimant letter for document #{document_id}",
                          service: :bgs,
                          name: "documents.find_claimant_letters") do
      client.documents.find_claimant_letters(document_id)
    end
  end

  def manage_claimant_letter_v2!(claim_id:, program_type_cd:, claimant_participant_id:)
    DBService.release_db_connections
    MetricsService.record("BGS: creates the claimant letter for \
                           claim_id: #{claim_id}, program_type_cd: #{program_type_cd}, \
                           claimant_participant_id: #{claimant_participant_id}",
                          service: :bgs,
                          name: "documents.manage_claimant_letter_v2") do
      client.documents.manage_claimant_letter_v2(
        claim_id: claim_id,
        program_type_cd: program_type_cd,
        claimant_participant_id: claimant_participant_id
      )
    end
  end

  def generate_tracked_items!(claim_id)
    DBService.release_db_connections
    MetricsService.record("BGS: generate tracked items for claim #{claim_id}",
                          service: :bgs,
                          name: "documents.generate_tracked_items") do
      client.documents.generate_tracked_items(claim_id)
    end
  end

  def find_contention_by_claim_id(claim_id)
    DBService.release_db_connections
    MetricsService.record("BGS: find contentions for veteran by claim_id #{claim_id}",
                          service: :bgs,
                          name: "contention.find_contention_by_claim_id") do
      client.contention.find_contention_by_claim_id(claim_id)
    end
  end

  private

  def current_user
    RequestStore[:current_user]
  end

  def can_access_cache_key(user, vbms_id)
    "bgs_can_access_#{user.css_id}_#{user.station_id}_#{vbms_id}"
  end

  def fetch_veteran_info_cache_key(vbms_id)
    "bgs_veteran_info_#{vbms_id}"
  end

  def init_client
    forward_proxy_url = FeatureToggle.enabled?(:bgs_forward_proxy) ? ENV["RUBY_BGS_PROXY_BASE_URL"] : nil

    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: ENV.fetch("USER_IP_ADDRESS", Rails.application.secrets.user_ip_address),
      client_station_id: current_user.station_id,
      client_username: current_user.css_id,
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      forward_proxy_url: forward_proxy_url,
      jumpbox_url: ENV["RUBY_BGS_JUMPBOX_URL"],
      log: true
    )
  end
  # :nocov:
end
