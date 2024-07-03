# frozen_string_literal: true

class AppealsReadyForDistribution
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    docket_number: "Docket Number",
    docket: "Docket",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    ready_for_distribution_at: "Ready for Distribution at",
    hearing_judge: "Hearing Judge",
    original_judge: "Original Deciding Judge",
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
      ready_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  # Uses DocketCoordinator to pull appeals ready for distribution
  # DocketCoordinator is used by Automatic Case Distribution so this will give us the most accurate list of appeals
  def self.ready_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        appeals = docket.ready_to_distribute_appeals
        if sym == :legacy
          legacy_rows(appeals, sym)
        else
          ama_rows(appeals, sym)
        end
      end
  end

  def self.legacy_rows(appeals, docket)
    appeals.map do |appeal|
      veteran_name = FullName.new(appeal["snamef"], nil, appeal["snamel"]).to_s
      vlj_name = FullName.new(appeal["vlj_namef"], nil, appeal["vlj_namel"]).to_s
      hearing_judge = vlj_name.empty? ? nil : vlj_name
      appeal_affinity = AppealAffinity.find_by(case_id: appeal["bfkey"], case_type: "VACOLS::Case")
      original_judge = appeal["prev_deciding_judge"].nil? ? nil : legacy_original_deciding_judge(appeal)

      {
        docket_number: appeal["tinum"],
        docket: docket.to_s,
        aod: appeal["aod"] == 1,
        cavc: appeal["cavc"] == 1,
        receipt_date: appeal["bfd19"],
        ready_for_distribution_at: appeal["bfdloout"],
        hearing_judge: hearing_judge,
        original_judge: original_judge,
        veteran_file_number: appeal["ssn"] || appeal["bfcorlid"],
        veteran_name: veteran_name,
        affinity_start_date: appeal_affinity&.affinity_start_date
      }
    end
  end

  def self.ama_rows(appeals, docket)
    appeals.map do |appeal|
      # This comes from the DistributionTask's assigned_at date
      ready_for_distribution_at =
        DistributionTask.assigned.where(appeal_id: appeal.id, appeal_type: Appeal.name).first&.assigned_at

      # only look for hearings that were held
      hearing_judge = appeal.hearings
        .filter { |hearing| hearing.disposition = Constants.HEARING_DISPOSITION_TYPES.held }
        .first&.judge&.full_name

      {
        docket_number: appeal.docket_number,
        docket: docket.to_s,
        aod: appeal.aod,
        cavc: appeal.cavc,
        receipt_date: appeal.receipt_date,
        ready_for_distribution_at: ready_for_distribution_at,
        hearing_judge: hearing_judge,
        original_judge: appeal.cavc? ? ama_cavc_original_deciding_judge(appeal) : nil,
        veteran_file_number: appeal.veteran_file_number,
        veteran_name: appeal.veteran&.name.to_s,
        affinity_start_date: appeal.appeal_affinity&.affinity_start_date
      }
    end
  end

  def self.ama_cavc_original_deciding_judge(appeal)
    source_appeal_id = CavcRemand.find_by(remand_appeal: appeal).source_appeal_id

    Task.find_by(appeal_id: source_appeal_id, appeal_type: Appeal.name, type: JudgeDecisionReviewTask.name)
      &.assigned_to&.css_id
  end

  def self.legacy_original_deciding_judge(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
    staff&.sdomainid || appeal["prev_deciding_judge"]
  end
end
