# frozen_string_literal: true

require "bgs"
require "fakes/end_product_store"

class Fakes::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  cattr_accessor :end_product_records
  cattr_accessor :inaccessible_appeal_vbms_ids
  cattr_accessor :veteran_records
  cattr_accessor :power_of_attorney_records
  cattr_accessor :address_records
  cattr_accessor :ssn_not_found
  cattr_accessor :rating_records
  cattr_accessor :rating_profile_records
  cattr_accessor :manage_claimant_letter_v2_requests
  cattr_accessor :generate_tracked_items_requests
  attr_accessor :client

  def self.create_veteran_records
    return if @veteran_records_created

    @veteran_records_created = true

    file_path = Rails.root.join("local", "vacols", "bgs_setup.csv")

    CSV.foreach(file_path, headers: true) do |row|
      row_hash = row.to_h
      file_number = row_hash["vbms_id"].chop
      veteran = Veteran.find_by_file_number(file_number) || Generators::Veteran.build(file_number: file_number)
      ama_begin_date = Constants::DATES["AMA_ACTIVATION"].to_date

      case row_hash["bgs_key"]
      when "has_rating"
        Generators::Rating.build(
          participant_id: veteran.participant_id
        )
      when "has_two_ratings"
        Generators::Rating.build(
          participant_id: veteran.participant_id
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: ama_begin_date + 2.days,
          issues: [
            { decision_text: "Left knee" },
            { decision_text: "PTSD" }
          ]
        )
      when "has_many_ratings"
        in_active_review_reference_id = "in-active-review-ref-id"
        in_active_review_receipt_date = Time.zone.parse("2018-04-01")
        completed_review_receipt_date = in_active_review_receipt_date - 30.days
        completed_review_reference_id = "cleared-review-ref-id"
        contention = Generators::Contention.build

        Generators::Rating.build(
          participant_id: veteran.participant_id
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          profile_date: ama_begin_date + 3.days,
          promulgation_date: ama_begin_date + 7.days,
          issues: [
            { decision_text: "Left knee" },
            { decision_text: "Right knee" },
            { decision_text: "PTSD" },
            { decision_text: "This rating is in active review", reference_id: in_active_review_reference_id },
            { decision_text: "I am on a completed Higher Level Review", contention_reference_id: contention.id }
          ]
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          profile_date: ama_begin_date - 10.days,
          promulgation_date: ama_begin_date - 5.days,
          issues: [
            { decision_text: "Issue before AMA not from a RAMP Review", reference_id: "before_ama_ref_id" },
            { decision_text: "Issue before AMA from a RAMP Review",
              associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_claim_id" },
              reference_id: "ramp_reference_id" }
          ]
        )
        ramp_begin_date = Date.new(2017, 11, 1)
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          profile_date: ramp_begin_date - 20.days,
          promulgation_date: ramp_begin_date - 15.days,
          issues: [
            { decision_text: "Issue before test AMA not from a RAMP Review", reference_id: "before_test_ama_ref_id" },
            { decision_text: "Issue before test AMA from a RAMP Review",
              associated_claims: { bnft_clm_tc: "683SCRRRAMP", clm_id: "ramp_test_claim_id" },
              reference_id: "ramp_reference_id" }
          ]
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: Time.zone.today - 395,
          profile_date: Time.zone.today - 400,
          issues: [
            { decision_text: "Old injury" }
          ]
        )
        hlr = HigherLevelReview.find_or_create_by!(
          veteran_file_number: veteran.file_number,
          receipt_date: in_active_review_receipt_date
        )
        epe = EndProductEstablishment.find_or_create_by!(
          reference_id: in_active_review_reference_id,
          veteran_file_number: veteran.file_number,
          source: hlr,
          payee_code: EndProduct::DEFAULT_PAYEE_CODE
        )
        RequestIssue.find_or_create_by!(
          decision_review: hlr,
          benefit_type: "compensation",
          end_product_establishment: epe,
          contested_rating_issue_reference_id: in_active_review_reference_id
        ) do |reqi|
          reqi.contested_rating_issue_profile_date = (Time.zone.today - 100).to_s
        end
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: { benefit_claim_id: in_active_review_reference_id }
        )
        previous_hlr = HigherLevelReview.find_or_create_by!(
          veteran_file_number: veteran.file_number,
          receipt_date: completed_review_receipt_date
        )
        cleared_epe = EndProductEstablishment.find_or_create_by!(
          reference_id: completed_review_reference_id,
          veteran_file_number: veteran.file_number,
          source: previous_hlr,
          synced_status: "CLR",
          payee_code: EndProduct::DEFAULT_PAYEE_CODE
        )
        RequestIssue.find_or_create_by!(
          decision_review: previous_hlr,
          benefit_type: "compensation",
          end_product_establishment: cleared_epe,
          contested_rating_issue_reference_id: completed_review_reference_id,
          contention_reference_id: contention.id
        ) do |reqi|
          reqi.contested_rating_issue_profile_date = Time.zone.today - 100
        end
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: { benefit_claim_id: completed_review_reference_id }
        )

        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: ama_begin_date + 10.days,
          issues: [
            { decision_text: "Lorem ipsum dolor sit amet, paulo scaevola abhorreant mei te, ex est mazim ornatus, at pro causae maiestatis." },
            { decision_text: "Inani movet maiestatis nec no, verear periculis signiferumque in sit." },
            { decision_text: "Et nibh euismod recusabo duo. Ne zril labitur eum, ei sit augue impedit detraxit." },
            { decision_text: "Usu et praesent suscipiantur, mea mazim timeam liberavisse et." },
            { decision_text: "At dicit omnes per, vim tale tota no." }
          ]
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: ama_begin_date + 12.days,
          issues: [
            { decision_text: "In mei labore oportere mediocritatem, vel ex dicta quidam corpora, fierent explicari liberavisse ei quo." },
            { decision_text: "Vel malis impetus ne, vim cibo appareat scripserit ne, qui lucilius consectetuer ex." },
            { decision_text: "Cu unum partiendo sadipscing has, eius explicari ius no." },
            { decision_text: "Cu unum partiendo sadipscing has, eius explicari ius no." },
            { decision_text: "Cibo pertinax hendrerit vis et, legendos euripidis no ius, ad sea unum harum." }
          ]
        )
      when "has_supplemental_claim_with_vbms_claim_id"
        claim_id = "600118926"
        sc = SupplementalClaim.find_or_create_by!(
          veteran_file_number: veteran.file_number
        )
        EndProductEstablishment.find_or_create_by!(
          reference_id: claim_id,
          veteran_file_number: veteran.file_number,
          source: sc,
          payee_code: EndProduct::DEFAULT_PAYEE_CODE
        )
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: { benefit_claim_id: claim_id }
        )
        sc
      when "has_higher_level_review_with_vbms_claim_id"
        claim_id = "600118951"
        contention_reference_id = veteran.file_number[0..4] + "1234"
        hlr = HigherLevelReview.find_or_create_by!(
          veteran_file_number: veteran.file_number
        )
        epe = EndProductEstablishment.find_or_create_by!(
          reference_id: claim_id,
          veteran_file_number: veteran.file_number,
          source: hlr,
          payee_code: EndProduct::DEFAULT_PAYEE_CODE
        )
        RequestIssue.find_or_create_by!(
          decision_review: hlr,
          benefit_type: "compensation",
          end_product_establishment: epe,
          contention_reference_id: contention_reference_id
        )
        Generators::Rating.build(
          participant_id: veteran.participant_id,
          promulgation_date: Time.zone.today - 40,
          profile_date: Time.zone.today - 30,
          issues: [
            {
              decision_text: "Higher Level Review was denied",
              contention_reference_id: contention_reference_id
            }
          ]
        )
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: { benefit_claim_id: claim_id }
        )
        hlr
      when "has_ramp_election_with_contentions"
        claim_id = "123456"
        ramp_election = RampElection.find_or_create_by!(
          veteran_file_number: veteran.file_number,
          established_at: 1.day.ago
        )
        EndProductEstablishment.find_or_create_by!(reference_id: claim_id, source: ramp_election) do |e|
          e.payee_code = EndProduct::DEFAULT_PAYEE_CODE
          e.veteran_file_number = veteran.file_number
          e.last_synced_at = 10.minutes.ago
          e.synced_status = "CLR"
        end
        Generators::Contention.build(text: "A contention!", claim_id: claim_id)
        Generators::EndProduct.build(
          veteran_file_number: veteran.file_number,
          bgs_attrs: { benefit_claim_id: claim_id }
        )
        ramp_election
      end
    end
  end

  def self.all_grants
    default_date = 10.days.ago.to_formatted_s(:short_date)
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: default_date,
        claim_type_code: "070RMND",
        end_product_type_code: "070",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "071",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "072",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "5",
        claim_receive_date: default_date,
        claim_type_code: "170APPACT",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "6",
        claim_receive_date: default_date,
        claim_type_code: "170APPACTPMC",
        end_product_type_code: "171",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "7",
        claim_receive_date: default_date,
        claim_type_code: "170PGAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "8",
        claim_receive_date: default_date,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "9",
        claim_receive_date: default_date,
        claim_type_code: "170RMDAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "10",
        claim_receive_date: default_date,
        claim_type_code: "170RMDPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "11",
        claim_receive_date: default_date,
        claim_type_code: "070BVAGRARC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "12",
        claim_receive_date: default_date,
        claim_type_code: "172BVAG",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "13",
        claim_receive_date: default_date,
        claim_type_code: "172BVAGPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "14",
        claim_receive_date: default_date,
        claim_type_code: "400CORRC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "15",
        claim_receive_date: default_date,
        claim_type_code: "400CORRCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "16",
        claim_receive_date: default_date,
        claim_type_code: "930RC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "17",
        claim_receive_date: default_date,
        claim_type_code: "930RCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      }
    ]
  end

  def self.existing_full_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      }
    ]
  end

  def self.existing_partial_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "071",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "072",
        status_type_code: "PEND"
      }
    ]
  end

  def self.no_grants
    []
  end

  def self.power_of_attorney_records
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

  def self.clean!
    self.ssn_not_found = false
    self.inaccessible_appeal_vbms_ids = []
    self.rating_records = {}
    self.rating_profile_records = {}
    end_product_store.clear!
    self.manage_claimant_letter_v2_requests = nil
    self.generate_tracked_items_requests = nil
  end

  def self.end_product_store
    @end_product_store ||= Fakes::EndProductStore.new
  end

  def self.store_end_product_record(veteran_id, end_product)
    end_product_store.store_end_product_record(veteran_id, end_product)
  end

  def get_end_products(veteran_id)
    store = self.class.end_product_store
    records = store.fetch_and_inflate(veteran_id) || store.fetch_and_inflate(:default) || {}
    records.values
  end

  def cancel_end_product(veteran_id, end_product_code, end_product_modifier)
    end_products = get_end_products(veteran_id)
    matching_eps = end_products.select do |ep|
      ep[:claim_type_code] == end_product_code && ep[:end_product_type_code] == end_product_modifier
    end
    matching_eps.each do |ep|
      ep[:status_type_code] = "CAN"
      self.class.store_end_product_record(veteran_id, ep)
    end
  end

  def fetch_veteran_info(vbms_id)
    # BGS throws a ShareError if the veteran has too high sensitivity
    fail BGS::ShareError, "Sensitive File - Access Violation !" unless can_access?(vbms_id)

    (self.class.veteran_records || {})[vbms_id]
  end

  def fetch_person_info(participant_id)
    # This is a limited set of test data, more fields are available.
    if participant_id == "5382910292"
      # This claimant is over 75 years old so they get automatic AOD
      {
        birth_date: "Sun, 05 Sep 1943 00:00:00 -0500",
        first_name: "Bob",
        middle_name: "Billy",
        last_name: "Vance"
      }
    elsif participant_id == "1129318238"
      {
        birth_date: "Sat, 05 Sep 1998 00:00:00 -0500",
        first_name: "Cathy",
        middle_name: "",
        last_name: "Smith",
        name_suffix: "Jr."
      }
    else
      {
        birth_date: "Sat, 05 Sep 1998 00:00:00 -0500",
        first_name: "Tom",
        middle_name: "Edward",
        last_name: "Brady"
      }
    end
  end

  def may_modify?(vbms_id, veteran_participant_id)
    !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
  end

  def can_access?(vbms_id)
    if current_user
      Rails.cache.fetch(can_access_cache_key(current_user, vbms_id), expires_in: 1.minute) do
        !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
      end
    else
      !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
    end
  end

  def bust_can_access_cache(user, vbms_id)
    Rails.cache.delete(can_access_cache_key(user, vbms_id))
  end

  def can_access_cache_key(user, vbms_id)
    "bgs_can_access_#{user.css_id}_#{user.station_id}_#{vbms_id}"
  end

  # TODO: add more test cases
  def fetch_poa_by_file_number(file_number)
    record = (self.class.power_of_attorney_records || {})[file_number]
    record ||= default_vso_power_of_attorney_record if file_number == 216_979_849
    record ||= default_power_of_attorney_record

    get_poa_from_bgs_poa(record[:power_of_attorney])
  end

  def fetch_poas_by_participant_id(participant_id)
    if participant_id == VSO_PARTICIPANT_ID
      return default_vsos_by_participant_id.map { |poa| get_poa_from_bgs_poa(poa) }
    end

    []
  end

  def fetch_poas_by_participant_ids(participant_ids)
    get_hash_of_poa_from_bgs_poas(
      participant_ids.map do |participant_id|
        vso = if participant_id == "CLAIMANT_WITH_PVA_AS_VSO"
                {
                  legacy_poa_cd: "071",
                  nm: "PARALYZED VETERANS OF AMERICA, INC.",
                  org_type_nm: "POA National Organization",
                  ptcpnt_id: "2452383"
                }
              else
                {
                  legacy_poa_cd: "100",
                  nm: "Attorney McAttorneyFace",
                  org_type_nm: "POA Attorney",
                  ptcpnt_id: "1234567"
                }
              end

        {
          ptcpnt_id: participant_id,
          power_of_attorney: vso
        }
      end
    )
  end

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

  # TODO: add more test cases
  def find_address_by_participant_id(participant_id)
    address = (self.class.address_records || {})[participant_id]
    address ||= default_address

    get_address_from_bgs_address(address)
  end

  def fetch_claimant_info_by_participant_id(_participant_id)
    default_claimant_info
  end

  def fetch_file_number_by_ssn(ssn)
    return if ssn_not_found

    (self.class.veteran_records || {}).each do |file_number, rec|
      if rec[:ssn].to_s == ssn.to_s
        return file_number
      end
    end
    nil # i.e. not found
  end

  def fetch_ratings_in_range(participant_id:, start_date:, end_date:)
    ratings = (self.class.rating_records || {})[participant_id]

    # mimic errors
    if participant_id == "locked_rating"
      return { reject_reason: "Locked Rating" }
    elsif participant_id == "backfilled_rating"
      return { reject_reason: "Converted or Backfilled Rating" }
    end

    # Simulate the error bgs throws if participant doesn't exist or doesn't have any ratings
    unless ratings
      fail Savon::Error, "java.lang.IndexOutOfBoundsException: Index: 0, Size: 0"
    end

    build_ratings_in_range(ratings, start_date, end_date)
  end

  def build_ratings_in_range(all_ratings, start_date, end_date)
    ratings = all_ratings.select do |r|
      start_date <= r[:prmlgn_dt] && end_date >= r[:prmlgn_dt]
    end

    # BGS returns the data not as an array if there is only one rating
    ratings = ratings.first if ratings.count == 1

    { rating_profile_list: ratings.empty? ? nil : { rating_profile: ratings } }
  end

  def fetch_rating_profile(participant_id:, profile_date:)
    self.class.rating_profile_records ||= {}
    self.class.rating_profile_records[participant_id] ||= {}

    rating_profile = self.class.rating_profile_records[participant_id][profile_date]

    # Simulate the error bgs throws if rating profile doesn't exist
    unless rating_profile
      fail Savon::Error, "a record does not exist for PTCPNT_VET_ID = '#{participant_id}'"\
        " and PRFL_DT = '#{profile_date}'"
    end

    rating_profile
  end

  def get_participant_id_for_user(user)
    return VSO_PARTICIPANT_ID if user.css_id =~ /.*_VSO/

    DEFAULT_PARTICIPANT_ID
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

  VSO_PARTICIPANT_ID = "4623321"
  DEFAULT_PARTICIPANT_ID = "781162"

  def current_user
    RequestStore[:current_user]
  end

  def default_claimant_info
    {
      relationship: "Spouse",
      payee_code: "10"
    }
  end

  def default_power_of_attorney_record
    {
      file_number: "633792224",
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
          legacy_poa_cd: "070",
          nm: "VIETNAM VETERANS OF AMERICA",
          org_type_nm: "POA National Organization",
          ptcpnt_id: "2452415"
        },
      ptcpnt_id: "600085544"
    }
  end

  def default_vsos_by_participant_id
    [
      {
        legacy_poa_cd: "070",
        nm: "VIETNAM VETERANS OF AMERICA",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452415"
      },
      {
        legacy_poa_cd: "071",
        nm: "PARALYZED VETERANS OF AMERICA, INC.",
        org_type_nm: "POA National Organization",
        ptcpnt_id: "2452383"
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
