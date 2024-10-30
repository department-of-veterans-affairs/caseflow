# frozen_string_literal: true

class AppealsDistributed
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    docket_number: "Docket Number",
    docket: "Docket",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    ready_for_distribution_at: "Ready for Distribution at",
    distributed_at: "Distributed At",
    hearing_judge: "Hearing Judge",
    veteran_file_number: "Veteran File number",
    veteran_name: "Veteran"
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

  # For each AMA appeal get its distributed case and use ActiveRecord relationships to get fields
  def self.ama_appeal(appeal, distributed_cases)
    distributed_case = distributed_cases.filter { |dc| dc.case_id == appeal.uuid }.first
    hearing_judge = appeal.hearings
      .filter { |hearing| hearing.disposition = Constants.HEARING_DISPOSITION_TYPES.held }
      .first&.judge&.full_name

    {
      docket_number: appeal.docket_number,
      docket: distributed_case.docket,
      aod: appeal.aod,
      cavc: appeal.cavc,
      receipt_date: appeal.receipt_date,
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      hearing_judge: hearing_judge,
      veteran_file_number: appeal.veteran_file_number,
      veteran_name: appeal.veteran&.name.to_s
    }
  end

  # Pull all the Legacy Appeals found
  def self.legacy_appeals(legacy_bfkeys, distributed_cases)
    # AOD is stored separately and doesn't come in as a part of VACOLS::Case relationships
    aod_appeals = VACOLS::Case.aod(legacy_bfkeys)

    LegacyAppeal.repository.vacols_records_for_appeals(legacy_bfkeys).map do |case_record|
      legacy_appeal(case_record, aod_appeals[case_record.bfkey], distributed_cases)
    end
  end

  def self.normalize_vacols_date(datetime)
    LegacyAppeal.repository.normalize_vacols_date(datetime)
  end

  # For each Legacy appeal get its distributed case and use ActiveRecord relationships to get fields
  def self.legacy_appeal(case_record, aod, distributed_cases)
    distributed_case = distributed_cases.filter { |dc| dc.case_id == case_record.bfkey }.first
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder
    veteran_name = FullName.new(correspondent_record.snamef, nil, correspondent_record.snamel).to_s

    {
      docket_number: folder_record.tinum,
      docket: distributed_case.docket,
      aod: aod,
      cavc: case_record.bfac == "7",
      receipt_date: normalize_vacols_date(case_record.bfd19),
      ready_for_distribution_at: distributed_case.ready_at,
      distributed_at: distributed_case.created_at,
      hearing_judge: case_record.case_hearings.first&.staff&.sdomainid,
      veteran_file_number: correspondent_record.ssn || case_record.bfcorlid,
      veteran_name: veteran_name
    }
  end
end
