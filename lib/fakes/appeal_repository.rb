require "ostruct"

# frozen_string_literal: true
class Fakes::AppealRepository
  class << self
    attr_accessor :issue_records
    attr_accessor :vacols_dispatch_update
    attr_accessor :location_updated_for
    attr_accessor :certified_appeal
    attr_accessor :certification
    cattr_accessor :appeal_records

    def records
      @records ||= {}
    end

    def clean!
      @records = {}
    end

    def load_user_case_assignments_from_vacols(_css_id)
      user_case_assignments = appeal_records || Fakes::Data::AppealData.default_records
      appeal = user_case_assignments.first
      # Create fake hearings for the first appeal if one doesn't already exist
      2.times { |i| Fakes::HearingRepository.create_hearing_for_appeal(i, appeal) } if Hearing
          .where(appeal: appeal).empty?

      user_case_assignments
    end
  end

  RAISE_VBMS_ERROR_ID = "raise_vbms_error_id".freeze
  RAISE_MULTIPLE_APPEALS_ERROR_ID = "raise_multiple_appeals_error".freeze

  def self.new(vacols_id, default_attrs_method_name, overrides = {})
    # Dynamically call the specified class method name to obtain
    # the hash of defualt values eg:
    #   AppealRepository.new("123C", :appeal_ready_to_certify)
    default_attrs = send(default_attrs_method_name)
    attrs = default_attrs.merge(overrides) # merge in overrides

    appeal = LegacyAppeal.new(vacols_id: vacols_id)
    appeal.assign_from_vacols(attrs)
    appeal
  end

  def self.transaction
    yield
  end

  def self.certify(appeal:, certification:)
    @certification = certification
    @certified_appeal = appeal
  end

  def self.update_vacols_after_dispatch!(appeal:, vacols_note:)
    self.vacols_dispatch_update = { appeal: appeal, vacols_note: vacols_note }
  end

  def self.update_location_after_dispatch!(appeal:)
    return unless appeal.active?
    self.location_updated_for = appeal
  end

  def self.raise_vbms_error_if_necessary(record)
    fail VBMS::ClientError if !record.nil? && RAISE_VBMS_ERROR_ID == record[:vbms_id]
  end

  def self.load_vacols_data(appeal)
    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record("load appeal #{appeal.vacols_id}", service: :vacols) do
      records[appeal.vacols_id]
    end

    return false unless record

    # clone this since we mutate it later
    record = record.dup

    raise_vbms_error_if_necessary(record)

    appeal.assign_from_vacols(record)

    true
  end

  def self.appeals_ready_for_hearing(vbms_id)
    Rails.logger.info("Load faked appeals ready for hearing for vbms id: #{vbms_id}")

    return_records = MetricsService.record("load appeals ready for hearing for vbms_id #{vbms_id}",
                                           service: :vacols) do
      records.select do |_, r|
        (r[:vbms_id] == vbms_id &&
        (r[:decision_date].nil? || r[:disposition] == "Remanded")) # &&
        # r[:form9_date])
      end
    end

    return_records.map do |vacols_id, r|
      LegacyAppeal.find_or_create_by(vacols_id: vacols_id).tap do |appeal|
        appeal.assign_from_vacols(r)
      end
    end
  end

  def self.close_undecided_appeal!(*); end

  def self.close_remand!(*); end

  def self.reopen_undecided_appeal!(*); end

  def self.reopen_remand!(*); end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    Rails.logger.info("Load faked VACOLS data for appeal VBMS ID: #{appeal.vbms_id}")
    Rails.logger.info("Decision Type:\n#{decision_type}")

    # simulate VACOLS returning 2 appeals for a given vbms_id
    fail Caseflow::Error::MultipleAppealsByVBMSID if RAISE_MULTIPLE_APPEALS_ERROR_ID == appeal[:vbms_id]

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record("load appeal #{appeal.vacols_id}", service: :vacols) do
      # TODO(jd): create a more dynamic setup
      records.find { |_, r| r[:vbms_id] == appeal.vbms_id }
    end

    return false unless record

    # clone this in case it accidentally gets mutated later
    record = record.dup

    appeal.vacols_id = record[0]
    appeal.assign_from_vacols(record[1])
  end

  def self.appeals_by_vbms_id(vbms_id)
    Rails.logger.info("Load faked VACOLS appeals data for vbms id: #{vbms_id}")

    return_records = MetricsService.record("load appeals for vbms_id #{vbms_id}",
                                           service: :vacols) do
      records.select { |_, r| r[:vbms_id] == vbms_id }
    end

    fail ActiveRecord::RecordNotFound if return_records.empty?

    return_records.map do |vacols_id, r|
      LegacyAppeal.find_or_create_by(vacols_id: vacols_id).tap do |appeal|
        appeal.assign_from_vacols(r)
      end
    end
  end

  def self.appeals_by_vbms_id_with_preloaded_status_api_attrs(vbms_id)
    appeals_by_vbms_id(vbms_id)
  end

  def self.remands_ready_for_claims_establishment
    []
  end

  def self.amc_full_grants(*)
    []
  end

  def self.issues(vacols_id)
    (issue_records || {})[vacols_id] || []
  end

  ## ALL SEED SCRIPTS BELOW THIS LINE ------------------------------
  # TODO: pull seed scripts into seperate object/module?
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def self.seed!(app_name: nil)
    return if Rails.env.test?

    # In demo mode, on app bootup (rails console or server) the app_name will be nil and we
    # want to load *all* of the seeds
    # In development mode, we call these on every request, so we only want to load the ones
    # relevant to our current app
    seed_certification_data! if app_name.nil? || app_name == "certification"
    seed_establish_claim_data! if app_name.nil? || app_name == "dispatch-arc"
    seed_intake_data! if app_name.nil? || app_name == "intake"
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  def self.certification_documents
    [
      Generators::Document.build(type: "NOD", category_procedural: true),
      Generators::Document.build(type: "SOC"),
      Generators::Document.build(type: "Form 9", category_medical: true),
      Generators::Document.build(type: "SSOC"),
      Generators::Document.build(type: "SSOC", received_at: 10.days.ago)
    ]
  end

  def self.establish_claim_documents
    certification_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago, category_other: true)
    ]
  end

  def self.establish_claim_multiple_decisions
    establish_claim_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 8.days.ago)
    ]
  end

  def self.seed_establish_claim_data!
    # Make every other case have two decision documents
    50.times.each do |i|
      Generators::LegacyAppeal.build(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}",
        vacols_record: [:full_grant_decided, :partial_grant_decided, :remand_decided][i % 3],
        documents: i.even? ? establish_claim_documents : establish_claim_multiple_decisions
      )
    end
  end

  def self.seed_appeal_ready_to_certify!
    nod, soc, form9, ssoc1, ssoc2 = certification_documents

    form9.vbms_document_id = "2"

    Generators::LegacyAppeal.build(
      vacols_id: "123C",
      vbms_id: "111223333S",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at + 2.days,
        form9_date: form9.received_at,
        ssoc_dates: [ssoc1.received_at, ssoc2.received_at],
        appellant_ssn: "111223333"
      },
      documents: [nod, soc, form9, ssoc1, ssoc2]
    )
  end

  def self.seed_appeal_no_bgs_address!
    nod, soc, form9, ssoc1, ssoc2 = certification_documents

    form9.vbms_document_id = "2"

    Generators::LegacyAppeal.build(
      vacols_id: "125C",
      vbms_id: "111225555S",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at + 2.days,
        form9_date: form9.received_at,
        ssoc_dates: [ssoc1.received_at, ssoc2.received_at],
        appellant_ssn: "111225555"
      },
      documents: [nod, soc, form9, ssoc1, ssoc2]
    )
  end

  def self.seed_appeal_mismatched_documents!
    nod, soc, form9 = certification_documents

    Generators::LegacyAppeal.build(
      vacols_id: "456C",
      vbms_id: "111224444S",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at,
        appellant_ssn: "111224444"
      },
      documents: [nod, soc]
    )
  end

  def self.seed_appeal_already_certified!
    Generators::LegacyAppeal.build(
      vacols_id: "789C",
      vacols_record: :certified
    )
  end

  def self.seed_appeal_ready_to_certify_with_informal_form9!
    nod, soc, form9 = certification_documents

    form9.vbms_document_id = "3"

    Generators::LegacyAppeal.build(
      vacols_id: "124C",
      vbms_id: "1112",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  def self.seed_appeal_raises_vbms_error!
    nod, soc, form9 = certification_documents

    Generators::LegacyAppeal.build(
      vacols_id: "000ERR",
      vbms_id: Fakes::AppealRepository::RAISE_VBMS_ERROR_ID,
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  def self.seed_appeal_not_ready!
    Generators::LegacyAppeal.build(
      vacols_id: "001ERR",
      vacols_record: :not_ready_to_certify
    )
  end

  def self.seed_certification_data!
    seed_appeal_ready_to_certify!
    seed_appeal_no_bgs_address!
    seed_appeal_mismatched_documents!
    seed_appeal_already_certified!
    seed_appeal_ready_to_certify_with_informal_form9!
    seed_appeal_raises_vbms_error!
    seed_appeal_not_ready!
  end

  # Intake demo file number guide:
  #
  # 15555555 - 95555555 are valid file numbers for RampElections
  # 85555555 will not have contentions for ramp refiling
  # 11555555 has an appeal ineligible for ramp
  # 12555555 has no active appeals
  # 13555555 has no ramp election
  # 14555555 has no compensation issues
  # 16555555 throws a sensitivity error
  # 19555555 throws a sex error
  # 23232323 is valid for AMA intake
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.seed_intake_data!
    Fakes::VBMSService.end_product_claim_ids_by_file_number ||= {}

    9.times do |i|
      file_number = "#{i + 1}5555555"
      claim_id = "FAKEEP123#{i}"

      Generators::Veteran.build(file_number: file_number)
      Generators::LegacyAppeal.build(
        vbms_id: "#{file_number}C",
        issues: (1..2).map { Generators::Issue.build },
        vacols_record: { template: :ready_to_certify, nod_date: 1.year.ago }
      )

      Generators::EndProduct.build(
        veteran_file_number: file_number,
        bgs_attrs: {
          benefit_claim_id: claim_id,
          status_type_code: ((i == 0) ? "PEND" : "CLR")
        }
      )

      if i != 7
        Generators::Contention.build(
          claim_id: claim_id,
          text: "Right knee service connection"
        )

        Generators::Contention.build(
          claim_id: claim_id,
          text: "Right hip service connection"
        )

        Generators::Contention.build(
          claim_id: claim_id,
          text: "PTSD rating increase"
        )
      end

      Fakes::VBMSService.end_product_claim_ids_by_file_number[file_number] = claim_id
    end

    Generators::LegacyAppeal.build(
      vbms_id: "11555555C",
      vacols_record: :activated
    )

    Generators::LegacyAppeal.build(
      vbms_id: "12555555C",
      vacols_record: :full_grant_decided
    )

    Generators::LegacyAppeal.build(
      vbms_id: "13555555C",
      vacols_record: :activated
    )

    Generators::LegacyAppeal.build(
      vbms_id: "14555555C",
      issues: (1..2).map { Generators::Issue.build(template: :education) }
    )

    Generators::LegacyAppeal.build(
      vbms_id: "25555555C",
      issues: (1..3).map { Generators::Issue.build }
    )

    Generators::LegacyAppeal.build(
      vbms_id: "16555555C",
      inaccessible: true
    )

    veteran = Generators::Veteran.build(file_number: "19555555", sex: nil, ssn: nil)
    Generators::LegacyAppeal.build(
      vbms_id: "19555555C",
      veteran: veteran,
      issues: (1..3).map { Generators::Issue.build }
    )

    # Rating data from BGS
    veteran = Generators::Veteran.build(file_number: "23232323")
    Generators::Rating.build(
      participant_id: veteran.participant_id
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def self.aod(_vacols_id)
    true
  end

  def self.case_assignment_exists?(_vacols_id)
    true
  end

  def self.remand_return_date(_vacols_id)
    2.days.ago
  end

  def self.regular_non_aod_docket_count
    123_456
  end

  def self.latest_docket_month
    11.months.ago.to_date.beginning_of_month
  end

  def self.docket_counts_by_month
    (1.year.ago.to_date..Time.zone.today).map { |d| Date.new(d.year, d.month, 1) }.uniq.each_with_index.map do |d, i|
      {
        "year" => d.year,
        "month" => d.month,
        "cumsum_n" => i * 10_000 + 3456,
        "cumsum_ready_n" => i * 5000 + 3456
      }
    end
  end
end
# rubocop:enable Metrics/ClassLength
