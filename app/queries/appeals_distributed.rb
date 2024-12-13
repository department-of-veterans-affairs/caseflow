# frozen_string_literal: true

class AppealsDistributed
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    case_id: "Case ID",
    docket_number: "Docket Number",
    docket: "Docket",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    ready_for_distribution_at: "Ready for Distribution at",
    distributed_at: "Distributed At",
    distributed_to: "Distributed To",
    genpop_query: "Distribution Type",
    original_judge: "Original Judge",
    prior_decision_date: "Prior Decision Date",
    hearing_judge: "Hearing Judge",
    hearing_date: "Hearing Date",
    veteran_file_number: "Veteran File number",
    veteran_name: "Veteran",
    affinity_start_date: "Affinity Start Date"
  }.freeze

  def self.generate_rows(record)
    HEADERS.keys.map { |key| record[key] }
  end

  def self.process
    # Convert results to CSV format
    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      # Iterate through results and add each row to CSV
      distributed_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  # DistributedCase table records all distributions that occur so can pull records from there
  # then use the case_id to find the appeal
  #
  # Legacy and AMA appeals look at different tables so need to separate them so can pull needed additional info
  # .where(created_at: Date.today - 10.days..Date.today)
  def self.distributed_appeals
    ama_uuids = []
    legacy_bfkeys = []
    distributed_cases = DistributedCase.all

    distributed_cases.map do |distributed_case|
      if distributed_case.ama_docket
        ama_uuids << distributed_case.case_id
      else
        legacy_bfkeys << distributed_case.case_id
      end
    end

    legacy_appeals(legacy_bfkeys, distributed_cases) + ama_appeals(ama_uuids, distributed_cases)
  end

  # Pull all the AMA Appeals at once
  def self.ama_appeals(ama_uuids, distributed_cases)
    Appeal.includes(:hearings, :tasks).where(uuid: ama_uuids).map { |appeal| ama_appeal(appeal, distributed_cases) }
  end

  # Pull all the Legacy Appeals found
  def self.legacy_appeals(legacy_bfkeys, distributed_cases)
    # AOD is stored separately and doesn't come in as a part of VACOLS::Case relationships
    aod_appeals = VACOLS::Case.aod(legacy_bfkeys)

    LegacyAppeal.repository.vacols_records_for_appeals(legacy_bfkeys).map do |case_record|
      legacy_appeal(case_record, aod_appeals[case_record.bfkey], distributed_cases)
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # For each AMA appeal get its distributed case and use ActiveRecord relationships to get fields
  def self.ama_appeal(appeal, distributed_cases)
    distributed_case = distributed_cases.filter { |dc| dc.case_id == appeal.uuid }.first
    hearing = appeal.hearings&.filter { |h| h.disposition = Constants.HEARING_DISPOSITION_TYPES.held }&.first
    original_task = appeal.cavc? ? ama_cavc_original_judge_task(appeal) : nil

    {
      case_id: distributed_case.case_id,
      docket_number: appeal.docket_number,
      docket: distributed_case.docket,
      aod: appeal.aod,
      cavc: appeal.cavc,
      receipt_date: appeal.receipt_date,
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      distributed_to: distributed_case.distribution&.judge&.css_id,
      genpop_query: distributed_case.genpop_query,
      original_judge: original_task&.assigned_to&.css_id,
      prior_decision_date: original_task&.closed_at&.to_date,
      hearing_judge: hearing&.judge&.css_id,
      hearing_date: hearing&.scheduled_for&.to_date,
      veteran_file_number: appeal.veteran_file_number,
      veteran_name: appeal.veteran&.name.to_s,
      affinity_start_date: appeal.appeal_affinity&.affinity_start_date
    }
  end

  # For each Legacy appeal get its distributed case and use ActiveRecord relationships to get fields
  def self.legacy_appeal(case_record, aod, distributed_cases)
    distributed_case = distributed_cases.filter { |dc| dc.case_id == case_record.bfkey }.first
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder
    original_case_record = VACOLS::Case.includes(:folder).where(folder: { tinum: folder_record.tinum },
                                                                bfddec: case_record.bfdpdcn)&.first
    prior_bfkeys = VACOLS::Folder.where(tinum: folder_record.tinum, titrnum: folder_record.titrnum).map(&:ticknum)
    hearing_record = VACOLS::CaseHearing.where(folder_nr: prior_bfkeys, hearing_disp: "H").max_by(&:hearing_date)
    hearing_date = LegacyAppeal.repository.normalize_vacols_date(hearing_record&.hearing_date).to_date if hearing_record
    cavc = if case_record.bfac == "3"
             original_case_record&.bfac == "7"
           else
             case_record.bfac == "7"
           end

    {
      case_id: distributed_case.case_id,
      docket_number: folder_record.tinum,
      docket: case_record.bfac == "3" ? "aoj_legacy" : distributed_case.docket,
      aod: aod,
      cavc: cavc,
      receipt_date: LegacyAppeal.repository.normalize_vacols_date(case_record.bfd19).to_date,
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      distributed_to: distributed_case.distribution&.judge&.css_id,
      genpop_query: distributed_case.genpop_query,
      original_judge: VACOLS::Staff.find_by(sattyid: original_case_record&.bfmemid)&.sdomainid,
      prior_decision_date: case_record.bfdpdcn,
      hearing_judge: hearing_record&.staff&.sdomainid,
      hearing_date: hearing_date || nil,
      veteran_file_number: correspondent_record.ssn || case_record.bfcorlid,
      veteran_name: FullName.new(correspondent_record.snamef, nil, correspondent_record.snamel).to_s,
      affinity_start_date: case_record.appeal_affinity&.affinity_start_date
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def self.ama_cavc_original_judge_task(appeal)
    source_appeal_id = CavcRemand.find_by(remand_appeal: appeal).source_appeal_id

    Task.find_by(appeal_id: source_appeal_id, appeal_type: Appeal.name, type: JudgeDecisionReviewTask.name)
  end
end
