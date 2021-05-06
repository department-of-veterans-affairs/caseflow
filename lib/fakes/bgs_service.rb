# frozen_string_literal: true

require "bgs"
require "fakes/end_product_store"
require "fakes/rating_store"

# rubocop:disable Metrics/ClassLength
class Fakes::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  cattr_accessor :end_product_records
  cattr_accessor :inaccessible_appeal_vbms_ids
  cattr_accessor :power_of_attorney_records
  cattr_accessor :address_records
  cattr_accessor :ssn_not_found
  cattr_accessor :manage_claimant_letter_v2_requests
  cattr_accessor :generate_tracked_items_requests
  attr_accessor :client

  DEFAULT_VSO_POA_FILE_NUMBER = 216_979_849
  VSO_PARTICIPANT_ID = "4623321"
  DEFAULT_PARTICIPANT_ID = "781162"

  class << self
    def can_access_cache_key(user, vbms_id)
      "bgs_can_access_#{user.css_id}_#{user.station_id}_#{vbms_id}"
    end

    def bust_can_access_cache(user, vbms_id)
      Rails.cache.delete(can_access_cache_key(user, vbms_id))
    end

    def mark_veteran_not_accessible(vbms_id)
      bust_can_access_cache(RequestStore[:current_user], vbms_id)
      self.inaccessible_appeal_vbms_ids ||= []
      self.inaccessible_appeal_vbms_ids << vbms_id
    end

    def create_veteran_records
      return if veteran_records_created?

      record_maker = Fakes::BGSServiceRecordMaker.new
      record_maker.call
    end

    def veteran_records_created?
      veteran_store.all_veteran_file_numbers.include?("872958715") # known file_number from local/vacols//bgs_setup.csv
    end

    def all_grants
      Fakes::BGSServiceGrants.all
    end

    def existing_full_grants
      Fakes::BGSServiceGrants.existing_full_grants
    end

    def existing_partial_grants
      Fakes::BGSServiceGrants.existing_partial_grants
    end

    def no_grants
      []
    end

    def power_of_attorney_records
      {
        "111225555" =>
          {
            file_number: "111225555",
            power_of_attorney:
              {
                legacy_poa_cd: "3QQ",
                nm: FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME,
                org_type_nm: "POA Attorney",
                ptcpnt_id: "ERROR-ID"
              },
            ptcpnt_id: "600085545"
          }
      }
    end

    def clean!
      self.ssn_not_found = false
      self.inaccessible_appeal_vbms_ids = []
      end_product_store.clear!
      rating_store.clear!
      veteran_store.clear!
      self.manage_claimant_letter_v2_requests = nil
      self.generate_tracked_items_requests = nil
    end

    def end_product_store
      @end_product_store ||= Fakes::EndProductStore.new
    end

    def veteran_store
      @veteran_store ||= Fakes::VeteranStore.new
    end

    def rating_store
      @rating_store ||= Fakes::RatingStore.new
    end

    delegate :store_end_product_record, to: :end_product_store
    delegate :store_veteran_record, to: :veteran_store
    delegate :store_rating_record, to: :rating_store
    delegate :store_rating_profile_record, to: :rating_store

    def get_veteran_record(file_number)
      veteran_store.fetch_and_inflate(file_number)
    end

    def edit_veteran_record(file_number, attr, new_value)
      vet_record = get_veteran_record(file_number)
      vet_record[attr] = new_value
      store_veteran_record(file_number, vet_record)
    end
  end

  def get_end_products(file_number)
    store = self.class.end_product_store
    records = store.fetch_and_inflate(file_number) || store.fetch_and_inflate(:default) || {}
    records.values
  end

  # Util method for further filtering a veteran's EPs by code, modifier, payee code, or claim date.
  # Each parameter is optional; if omitted or set to nil, it won't be used for filtering.
  def select_end_products(file_number, code: nil, modifier: nil, payee_code: nil, claim_date: nil)
    requirements = {
      claim_type_code: code,
      end_product_type_code: modifier,
      payee_type_code: payee_code,
      claim_receive_date: claim_date&.strftime("%m/%d/%Y")
    }.compact
    get_end_products(file_number).select do |ep|
      requirements.map { |key, value| ep[key] == value }.all?
    end
  end

  def find_contentions_by_claim_id(claim_id)
    contentions = self.class.end_product_store.inflated_bgs_contentions_for(claim_id)

    if contentions.blank?
      fail BGS::ShareError, "No benefit claims found with claim id: #{claim_id.to_i}"
    end

    format_contentions(contentions)
  end

  # :reek:FeatureEnvy
  def find_current_rating_profile_by_ptcpnt_id(participant_id)
    record = get_rating_record(participant_id)
    fail BGS::ShareError, "No Record Found" if record.blank?

    # We grab the latest promulgated rating, assuming that under the hood BGS also does.
    rating = record[:ratings].max_by { |rt| rt[:prmlgn_dt] }
    rating_at_issue_profile_data(rating)
  end

  def format_contentions(contentions)
    { contentions: contentions.map { |contention| format_contention(contention) } }
  end

  def format_contention(contention)
    {
      cntntn_id: contention[:reference_id],
      clmnt_txt: contention[:text],
      cntntn_type_cd: contention[:type_code],
      clsfcn_id: contention[:classification_id],
      clsfcn_txt: contention[:classification_text],
      med_ind: contention[:medical_indicator],
      orig_source_type_cd: contention[:orig_source_type_code],
      begin_dt: contention[:begin_date],
      clm_id: contention[:claim_id],
      special_issues: contention[:special_issues]
    }
  end

  def get_veteran_record(file_number)
    self.class.get_veteran_record(file_number)
  end

  def get_rating_record(participant_id)
    self.class.rating_store.fetch_and_inflate(participant_id) || {}
  end

  # benefit_type_code is not available data on end product data we fetch from BGS,
  # and isn't part of the end product store in fakes
  def cancel_end_product(file_number, end_product_code, end_product_modifier, payee_code, _benefit_type)
    matching_eps = select_end_products(file_number,
                                       code: end_product_code,
                                       modifier: end_product_modifier,
                                       payee_code: payee_code)
    matching_eps.each do |ep|
      ep[:status_type_code] = "CAN"
      self.class.store_end_product_record(file_number, ep)
    end
  end

  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/MethodLength
  def update_benefit_claim(veteran_file_number:, payee_code:, claim_date:, benefit_type_code:, modifier:, new_code:)
    matching_eps = select_end_products(veteran_file_number,
                                       modifier: modifier,
                                       payee_code: payee_code,
                                       claim_date: claim_date)

    # BGS throws a ShareError if matching_ep is blank
    veteran = Veteran.find_by(file_number: veteran_file_number)
    fail BGS::ShareError, "No Veteran Found" unless veteran

    if matching_eps.blank?
      return { benefit_claim_record: { pre_dschrg_type_cd: nil },
               life_cycle_record: nil,
               participant_record: nil,
               return_cod: "GUIE50004",
               return_message: "Benefit Claim not found on Corporate Database",
               suspence_record: nil }
    end

    matching_eps.each do |ep|
      ep[:claim_type_code] = new_code
      self.class.store_end_product_record(veteran_file_number, ep)
    end

    # Actual success message
    { benefit_claim_record: { pre_dschrg_type_cd: nil },
      life_cycle_record: nil,
      participant_record: nil,
      return_code: "GUIE02210",
      return_message: "A benefit claim has been changed",
      suspence_record: nil }
  end
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/MethodLength

  def fetch_veteran_info(vbms_id)
    # BGS throws a ShareError if the veteran has too high sensitivity
    fail BGS::ShareError, "Sensitive File - Access Violation !" unless can_access?(vbms_id)

    get_veteran_record(vbms_id)
  end

  # rubocop:disable Metrics/MethodLength
  def fetch_person_info(participant_id)
    veteran = Veteran.find_by(participant_id: participant_id)
    # This is a limited set of test data, more fields are available.
    if participant_id == "5382910292"
      # This claimant is over 75 years old so they get automatic AOD
      {
        birth_date: DateTime.new(1943, 9, 5),
        first_name: "Bob",
        middle_name: "Billy",
        last_name: "Vance",
        ssn_nbr: "666001234",
        email_address: "bob.vance@caseflow.gov"
      }
    elsif participant_id == "1129318238"
      {
        birth_date: DateTime.new(1998, 9, 5),
        first_name: "Cathy",
        middle_name: "",
        last_name: "Smith",
        name_suffix: "Jr.",
        ssn_nbr: "666002222",
        email_address: "cathy.smith@caseflow.gov"
      }
    elsif participant_id == "600153863"
      {
        birth_date: DateTime.new(1998, 9, 5),
        fist_name: "Clarence",
        middle_name: "",
        last_name: "Darrow",
        ssn_nbr: "666003333",
        email_address: "clarence.darrow@caseflow.gov"
      }
    elsif participant_id.starts_with?("RANDOM_CLAIMANT_PID")
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      {
        birth_date: Faker::Date.birthday(min_age: 35, max_age: 80).to_datetime,
        first_name: first_name,
        middle_name: "",
        last_name: last_name,
        ssn_nbr: "666005555",
        email_address: "#{first_name}.#{last_name}@email.com"
      }
    elsif veteran.present?
      {
        birth_date: veteran&.date_of_birth && Date.strptime(veteran&.date_of_birth, "%m/%d/%Y"),
        first_name: veteran.first_name,
        middle_name: veteran.middle_name,
        last_name: veteran.last_name,
        ssn_nbr: veteran.ssn,
        email_address: veteran.email_address
      }
    else
      {
        birth_date: DateTime.new(1998, 9, 5),
        first_name: "Tom",
        middle_name: "Edward",
        last_name: "Brady",
        ssn_nbr: "666004444",
        email_address: "tom.brady@caseflow.gov"
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def station_conflict?(vbms_id, _veteran_participant_id)
    (self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
  end

  def can_access?(vbms_id)
    is_accessible = !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)

    if current_user
      Rails.cache.fetch(can_access_cache_key(current_user, vbms_id), expires_in: 1.minute) do
        is_accessible
      end
    else
      is_accessible
    end
  end

  def bust_can_access_cache(user, vbms_id)
    self.class.bust_can_access_cache(user, vbms_id)
  end

  def can_access_cache_key(user, vbms_id)
    self.class.can_access_cache_key(user, vbms_id)
  end

  # TODO: add more test cases
  def fetch_poa_by_file_number(file_number)
    return {} if file_number == "no-such-file-number"

    record = (self.class.power_of_attorney_records || {})[file_number]
    record ||= default_vso_power_of_attorney_record if file_number == DEFAULT_VSO_POA_FILE_NUMBER
    record ||= default_power_of_attorney_record(file_number)

    get_claimant_poa_from_bgs_poa(record)
  end

  # The participant_id here is for a User, not a Claimant.
  # I.e. returns the list of VSOs that a User represents.
  def fetch_poas_by_participant_id(participant_id)
    if participant_id == VSO_PARTICIPANT_ID
      return default_vsos_by_participant_id.map { |poa| get_poa_from_bgs_poa(poa[:power_of_attorney]) }
    end

    []
  end

  # The participant IDs here are for Claimants.
  # I.e. returns the list of POAs that represent the Claimants.
  # rubocop:disable Metrics/MethodLength
  def fetch_poas_by_participant_ids(participant_ids)
    return {} if participant_ids == ["no-such-pid"]

    get_hash_of_poa_from_bgs_poas(
      participant_ids.map do |participant_id|
        vso = if participant_id.starts_with?("CLAIMANT_WITH_PVA_AS_VSO")
                {
                  legacy_poa_cd: Fakes::BGSServicePOA::PARALYZED_VETERANS_LEGACY_POA_CD,
                  nm: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_NAME,
                  org_type_nm: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
                  ptcpnt_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
                }
              else
                {
                  legacy_poa_cd: "100",
                  nm: "Clarence Darrow",
                  org_type_nm: "POA Attorney",
                  ptcpnt_id: "1234567"
                }
              end

        {
          ptcpnt_id: participant_id,
          file_number: "00001234",
          power_of_attorney: vso
        }
      end
    )
  end
  # rubocop:enable Metrics/MethodLength

  def fetch_limited_poas_by_claim_ids(claim_ids)
    result = {}
    Array.wrap(claim_ids).each do |claim_id|
      if claim_id.include? "HAS_LIMITED_POA_WITH_ACCESS"
        result[claim_id] = { limited_poa_code: "OU3", limited_poa_access: "Y" }
      elsif claim_id.include? "HAS_LIMITED_POA_WITHOUT_ACCESS"
        result[claim_id] = { limited_poa_code: "007", limited_poa_access: "N" }
      end
    end

    result.empty? ? nil : result
  end

  def poas_list
    [
      { ptcpnt_id: "12345678", nm: "NANCY BAUMBACH", org_type_nm: "POA Attorney" },
      { ptcpnt_id: "55114884", nm: "RICH TREUTING SR.", org_type_nm: "POA Agent" },
      { ptcpnt_id: "56242925", nm: "MADELINE JENKINS", org_type_nm: "POA Attorney" },
      { ptcpnt_id: "21543986", nm: "ACADIA VETERAN SERVICES", org_type_nm: "POA State Organization" },
      { ptcpnt_id: "56154689", nm: "RANDALL KOHLER III", org_type_nm: "POA Attorney" }
    ]
  end

  def pay_grade_list
    [
      { code: "E1", name: "E-1" },
      { code: "E2", name: "E-2" },
      { code: "E3", name: "E-3" },
      { code: "E4", name: "E-4" },
      { code: "E5", name: "E-5" },
      { code: "E6", name: "E-6" },
      { code: "E9", name: "E-9" },
      { code: "O1", name: "O-1" },
      { code: "O2", name: "O-2" },
      { code: "O3", name: "O-3" },
      { code: "O4", name: "O-4" },
      { code: "O5", name: "O-5" },
      { code: "WO1", name: "WO-1" },
      { code: "WO2", name: "WO-2" },
      { code: "WO3", name: "WO-3" },
      { code: "WO4", name: "WO-4" }
    ]
  end

  def get_security_profile(username:, station_id:)
    if username == "BVAAABSHIRE"
      { job_title: "Senior Veterans Service Representative" }
    else
      { job_title: "Legal Clerk" }
    end
  end

  # TODO: add more test cases
  def find_address_by_participant_id(participant_id)
    address = (self.class.address_records || {})[participant_id]
    address ||= default_address

    get_address_from_bgs_address(address)
  end

  def fetch_claimant_info_by_participant_id(participant_id)
    veteran = Veteran.find_by(participant_id: participant_id)
    if veteran.present?
      {
        relationship: "Veteran",
        payee_code: "00"
      }
    else
      claimant = Array.wrap(find_all_relationships(participant_id)).find { |rel| rel.dig(:ptcpnt_id) == participant_id }

      {
        relationship: claimant&.dig(:relationship_type) || "Spouse",
        payee_code: claimant&.dig(:default_payee_code) || "10"
      }
    end
  end

  def fetch_person_by_ssn(ssn)
    return if ssn_not_found

    self.class.veteran_store.all_veteran_file_numbers.each do |file_number|
      record = get_veteran_record(file_number)
      return record if record[:ssn].to_s == ssn.to_s
    end
    nil # not found
  end

  def fetch_file_number_by_ssn(ssn)
    return if ssn_not_found

    person = fetch_person_by_ssn(ssn)
    return person[:file_number] if person
  end

  def fetch_ratings_in_range(participant_id:, start_date:, end_date:)
    ratings = get_rating_record(participant_id)[:ratings] || []

    # mimic errors
    if participant_id == "locked_rating"
      return { reject_reason: "Locked Rating" }
    elsif participant_id == "backfilled_rating"
      return { reject_reason: "Converted or Backfilled Rating" }
    end

    # Simulate the error bgs throws if participant doesn't exist or doesn't have any ratings
    if ratings.blank?
      fail BGS::NoRatingsExistForVeteran, "No Ratings exist for this Veteran"
    end

    format_promulgated_rating(build_ratings_in_range(ratings, start_date, end_date))
  end

  def fetch_rating_profile(participant_id:, profile_date:)
    stored_rating_profile(participant_id: participant_id, profile_date: profile_date)
  end

  def fetch_rating_profiles_in_range(participant_id:, start_date:, end_date:)
    ratings = get_rating_record(participant_id)[:ratings] || []
    # Simulate the response if participant doesn't exist or doesn't have any ratings
    if ratings.blank?
      return { response: { response_text: "No Data Found" } }
    end

    format_rating_at_issue(build_ratings_in_range(ratings, start_date, end_date))
  end

  def build_ratings_in_range(all_ratings, start_date, end_date)
    ratings = all_ratings.select do |rating|
      rating[:prmlgn_dt].nil? || (start_date <= rating[:prmlgn_dt] && end_date >= rating[:prmlgn_dt])
    end

    # BGS returns the data not as an array if there is only one rating
    ratings = ratings.first if ratings.count == 1

    ratings
  end

  def format_promulgated_rating(ratings)
    { rating_profile_list: ratings.empty? ? nil : { rating_profile: ratings } }
  end

  def format_rating_at_issue(ratings)
    ratings = Array.wrap(ratings).map do |rating|
      rating_at_issue_profile_data(rating)
    end

    { rba_profile_list: ratings.empty? ? nil : { rba_profile: ratings } }
  end

  def rating_at_issue_profile_data(rating)
    promulgated_rating_data = rating.dig(:comp_id)

    # If a PromulgatedRating was originally stored in rating_store
    # convert to be compatible with RatingAtIssue
    if promulgated_rating_data.present?
      rating_profile = stored_rating_profile(
        participant_id: promulgated_rating_data[:ptcpnt_vet_id],
        profile_date: promulgated_rating_data[:prfil_dt]
      )

      {
        prfl_dt: promulgated_rating_data[:prfil_dt],
        ptcpnt_vet_id: promulgated_rating_data[:ptcpnt_vet_id],
        prmlgn_dt: rating[:prmlgn_dt],
        rba_issue_list: { rba_issue: rating_profile[:rating_issues] },
        disability_list: { disability: rating_profile[:disabilities] },
        rba_claim_list: { rba_claim: rating_profile[:associated_claims] }
      }
    else
      rating
    end
  end

  def stored_rating_profile(participant_id:, profile_date:)
    normed_date_key = Fakes::RatingStore.normed_profile_date_key(profile_date).to_sym
    rating_profile = (get_rating_record(participant_id)[:profiles] || {})[normed_date_key]

    # Simulate the error bgs throws if rating profile doesn't exist
    unless rating_profile
      fail Savon::Error, "a record does not exist for PTCPNT_VET_ID = '#{participant_id}'"\
        " and PRFL_DT = '#{profile_date}'"
    end

    rating_profile
  end

  def get_participant_id_for_user(user)
    get_participant_id_for_css_id_and_station_id(user.css_id, user.station_id)
  end

  def get_participant_id_for_css_id_and_station_id(css_id, _station_id)
    /.*_VSO/.match?(css_id) ? VSO_PARTICIPANT_ID : DEFAULT_PARTICIPANT_ID
  end

  # rubocop:disable Metrics/MethodLength
  def find_all_relationships(*)
    [
      {
        authzn_change_clmant_addrs_ind: nil,
        authzn_poa_access_ind: "Y",
        award_begin_date: nil,
        award_end_date: nil,
        award_ind: "N",
        award_type: "CPL",
        date_of_birth: "02171972",
        date_of_death: "03072014",
        dependent_reason: nil,
        dependent_terminate_date: nil,
        email_address: nil,
        fiduciary: nil,
        file_number: "123456789",
        first_name: "BOB",
        gender: "M",
        last_name: "VANCE",
        middle_name: "D",
        poa: "DISABLED AMERICAN VETERANS",
        proof_of_dependecy_ind: nil,
        ptcpnt_id: "CLAIMANT_WITH_PVA_AS_VSO",
        relationship_begin_date: nil,
        relationship_end_date: nil,
        relationship_type: "Spouse",
        ssn: "123456789",
        ssn_verified_ind: "Unverified",
        terminate_reason: nil
      },
      {
        authzn_change_clmant_addrs_ind: nil,
        authzn_poa_access_ind: nil,
        award_begin_date: nil,
        award_end_date: nil,
        award_ind: "N",
        award_type: "CPL",
        date_of_birth: "04121995",
        date_of_death: nil,
        dependent_reason: nil,
        dependent_terminate_date: nil,
        email_address: "cathy@gmail.com",
        fiduciary: nil,
        file_number: nil,
        first_name: "CATHY",
        gender: nil,
        last_name: "SMITH",
        middle_name: nil,
        poa: nil,
        proof_of_dependecy_ind: nil,
        ptcpnt_id: "1129318238",
        relationship_begin_date: "08121999",
        relationship_end_date: nil,
        relationship_type: "Child",
        ssn: nil,
        ssn_verified_ind: nil,
        terminate_reason: nil
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  # We're currently only using the doc_reference_id and development_item_reference_id to track
  # that the call succeeded, so I am just having the fakes return these dummy values
  def manage_claimant_letter_v2!(claim_id:, program_type_cd:, claimant_participant_id:)
    self.class.manage_claimant_letter_v2_requests ||= {}

    self.class.manage_claimant_letter_v2_requests[claim_id] = {
      program_type_cd: program_type_cd,
      claimant_participant_id: claimant_participant_id
    }

    "doc_reference_id_result"
  end

  def generate_tracked_items!(claim_id)
    self.class.generate_tracked_items_requests ||= {}
    self.class.generate_tracked_items_requests[claim_id] = true

    "development_item_reference_id_result"
  end

  private

  def current_user
    RequestStore[:current_user]
  end

  def default_power_of_attorney_record(file_number = nil)
    file_number ||= "633792224"
    {
      file_number: "#{file_number}",
      power_of_attorney:
        {
          legacy_poa_cd: "3QQ",
          nm: FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME,
          org_type_nm: "POA Attorney",
          ptcpnt_id: "600153863"
        },
      ptcpnt_id: "600085544"
    }
  end

  def default_vso_power_of_attorney_record
    {
      file_number: "216979849",
      power_of_attorney:
        {
          legacy_poa_cd: Fakes::BGSServicePOA::VIETNAM_VETERANS_LEGACY_POA_CD,
          nm: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_NAME,
          org_type_nm: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID
        },
      ptcpnt_id: "600085544"
    }
  end

  def default_vsos_by_participant_id
    [
      {
        power_of_attorney: {
          legacy_poa_cd: Fakes::BGSServicePOA::VIETNAM_VETERANS_LEGACY_POA_CD,
          nm: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_NAME,
          org_type_nm: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: Fakes::BGSServicePOA::VIETNAM_VETERANS_VSO_PARTICIPANT_ID
        }
      },
      {
        power_of_attorney: {
          legacy_poa_cd: Fakes::BGSServicePOA::PARALYZED_VETERANS_LEGACY_POA_CD,
          nm: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_NAME,
          org_type_nm: Fakes::BGSServicePOA::POA_NATIONAL_ORGANIZATION,
          ptcpnt_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
        }
      }
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def default_address
    {
      addrs_one_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1,
      addrs_three_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3,
      addrs_two_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2,
      city_nm: FakeConstants.BGS_SERVICE.DEFAULT_CITY,
      cntry_nm: FakeConstants.BGS_SERVICE.DEFAULT_COUNTRY,
      efctv_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_lctn_id: "283",
      jrn_obj_id: "SHARE  - PCAN",
      jrn_status_type_cd: "U",
      jrn_user_id: "CASEFLOW1",
      postal_cd: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
      ptcpnt_addrs_id: "15069061",
      ptcpnt_addrs_type_nm: "Mailing",
      ptcpnt_id: "600085544",
      shared_addrs_ind: "N",
      trsury_addrs_four_txt: "SAN FRANCISCO CA",
      trsury_addrs_one_txt: "Jamie Fakerton",
      trsury_addrs_three_txt: "APT 2",
      trsury_addrs_two_txt: "9999 MISSION ST",
      trsury_seq_nbr: "5",
      zip_prefix_nbr: FakeConstants.BGS_SERVICE.DEFAULT_ZIP
    }
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
