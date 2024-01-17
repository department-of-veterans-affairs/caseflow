# frozen_string_literal: true

class Fakes::BGSServiceRecordMaker
  KNOWN_REQUEST_ISSUE_REFERENCE_ID = "in-active-review-ref-id"

  def call
    process_csv
  end

  private

  def csv_file_path
    Rails.root.join("local", "vacols", "bgs_setup.csv")
  end

  def ama_begin_date
    @ama_begin_date ||= Constants::DATES["AMA_ACTIVATION"].to_date
  end

  def process_csv
    CSV.foreach(csv_file_path, headers: true) do |row|
      row_hash = row.to_h
      file_number = row_hash["vbms_id"].chop
      veteran = Veteran.find_by_file_number(file_number) ||
                Generators::Veteran.build(map_corres_to_veteran(file_number))

      method_name = row_hash["bgs_key"]

      if method_name
        send(method_name.to_sym, veteran)
      end
    end
  end

  # For veterans, maps attributes from VACOLS CORRES table to Veteran record
  def map_corres_to_veteran(file_number)
    vacols_case = VACOLS::Case.find_by(bfcorlid: "#{file_number}S")
    corres = VACOLS::Correspondent.find_by(stafkey: vacols_case&.bfcorkey)
    if corres&.susrtyp == "VETERAN"
      {
        file_number: file_number,
        first_name: corres.snamef,
        last_name: corres.snamel,
        middle_name: corres.snamemi,
        suffix_name: corres.ssalut
        # See lib/generators/veteran.rb:12 for other attributes
      }
    else
      {
        file_number: file_number
      }
    end
  end

  # rubocop:disable Naming/PredicateName
  def has_rating(veteran)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: Date.new(2019, 10, 11),
      profile_date: Date.new(2019, 10, 11),
      issues: [
        { decision_text: "Service connection is granted for PTSD at 10 percent, effective 10/11/2019." },
        { decision_text: "Service connection is denied for right knee condition." }
      ]
    )
  end

  def has_two_ratings(veteran)
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id
    )
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: ama_begin_date + 2.days,
      issues: [
        { decision_text: "Left knee" },
        { decision_text: "PTSD" }
      ]
    )
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def has_many_ratings(veteran)
    in_active_review_reference_id = KNOWN_REQUEST_ISSUE_REFERENCE_ID
    in_active_review_receipt_date = Time.zone.parse("2018-04-01")
    completed_review_receipt_date = in_active_review_receipt_date - 30.days
    completed_review_reference_id = "cleared-review-ref-id"
    contention = Generators::Contention.build

    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id
    )
    Generators::PromulgatedRating.build(
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
    Generators::PromulgatedRating.build(
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
    Generators::PromulgatedRating.build(
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
    Generators::PromulgatedRating.build(
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
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: ama_begin_date + 10.days,
      issues: [
        { decision_text: "Lorem ipsum dolor sit amet, paulo scaevola abhorreant mei te, ex est mazim ornatus." },
        { decision_text: "Inani movet maiestatis nec no, verear periculis signiferumque in sit." },
        { decision_text: "Et nibh euismod recusabo duo. Ne zril labitur eum, ei sit augue impedit detraxit." },
        { decision_text: "Usu et praesent suscipiantur, mea mazim timeam liberavisse et." },
        { decision_text: "At dicit omnes per, vim tale tota no." }
      ]
    )
    Generators::PromulgatedRating.build(
      participant_id: veteran.participant_id,
      promulgation_date: ama_begin_date + 12.days,
      issues: [
        { decision_text: "In mei labore oportere mediocritatem, vel ex dicta quidam corpora." },
        { decision_text: "Vel malis impetus ne, vim cibo appareat scripserit ne, qui lucilius consectetuer ex." },
        { decision_text: "Cu unum partiendo sadipscing has, eius explicari ius no." },
        { decision_text: "Cu unum partiendo sadipscing has, eius explicari ius no." },
        { decision_text: "Cibo pertinax hendrerit vis et, legendos euripidis no ius, ad sea unum harum." }
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def has_supplemental_claim_with_vbms_claim_id(veteran)
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
  end

  # rubocop:disable Metrics/MethodLength
  def has_higher_level_review_with_vbms_claim_id(veteran)
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
    Generators::PromulgatedRating.build(
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
  end
  # rubocop:enable Metrics/MethodLength

  def has_ramp_election_with_contentions(veteran)
    claim_id = "123456"
    ramp_election = RampElection.find_or_create_by!(
      veteran_file_number: veteran.file_number,
      established_at: 1.day.ago
    )
    EndProductEstablishment.find_or_create_by!(reference_id: claim_id, source: ramp_election) do |epe|
      epe.payee_code = EndProduct::DEFAULT_PAYEE_CODE
      epe.veteran_file_number = veteran.file_number
      epe.last_synced_at = 10.minutes.ago
      epe.synced_status = "CLR"
    end
    Generators::Contention.build(text: "A contention!", claim_id: claim_id)
    Generators::EndProduct.build(
      veteran_file_number: veteran.file_number,
      bgs_attrs: { benefit_claim_id: claim_id }
    )
    ramp_election
  end
  # rubocop:enable Naming/PredicateName
end
