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
    target_distro_date: "Target Distro Date",
    days_before_goal_date: "Days Before Goal Date",
    hearing_judge: "Hearing Judge",
    original_judge_id: "Original Deciding Judge ID",
    original_judge_name: "Original Deciding Judge",
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
          ama_rows(appeals, docket, sym)
        end
      end
  end

  def self.legacy_rows(appeals, sym)
    appeals.map do |appeal|
      build_legacy_appeal_row(appeal, sym)
    end
  end

  def self.build_legacy_appeal_row(appeal, sym)
    veteran_name = format_veteran_name(appeal["snamef"], appeal["snamel"])
    hearing_judge = format_vlj_name(appeal["vlj_namef"], appeal["vlj_namel"])
    appeal_affinity = fetch_affinity_start_date(appeal["bfkey"])

    {
      docket_number: appeal["tinum"],
      docket: sym.to_s,
      aod: appeal["aod"] == 1,
      cavc: appeal["cavc"] == 1,
      receipt_date: appeal["bfd19"],
      ready_for_distribution_at: appeal["bfdloout"],
      target_distro_date: "N/A",
      days_before_goal_date: "N/A",
      hearing_judge: hearing_judge,
      original_judge_id: legacy_original_deciding_judge(appeal),
      original_judge_name: legacy_original_deciding_judge_name(appeal),
      veteran_file_number: appeal["ssn"] || appeal["bfcorlid"],
      veteran_name: veteran_name,
      affinity_start_date: appeal_affinity
    }
  end

  def self.format_vlj_name(first_name, last_name)
    name = FullName.new(first_name, nil, last_name).to_s
    name.empty? ? nil : name
  end

  def self.format_veteran_name(first_name, last_name)
    FullName.new(first_name, nil, last_name).to_s
  end

  def self.fetch_affinity_start_date(case_id)
    appeal_affinity = AppealAffinity.find_by(case_id: case_id, case_type: "VACOLS::Case")
    appeal_affinity&.affinity_start_date
  end

  def self.ama_rows(appeals, docket, sym)
    appeals.map do |appeal|
      # This comes from the DistributionTask's assigned_at date
      ready_for_distribution_at = distribution_task_query(appeal)
      # only look for hearings that were held
      hearing_judge = with_held_hearings(appeal)

      priority_appeal = appeal.aod || appeal.cavc
      {
        docket_number: appeal.docket_number,
        docket: sym.to_s,
        aod: appeal.aod,
        cavc: appeal.cavc,
        receipt_date: appeal.receipt_date,
        ready_for_distribution_at: ready_for_distribution_at,
        target_distro_date: priority_appeal ? "N/A" : target_distro_date(appeal.receipt_date, docket),
        days_before_goal_date: priority_appeal ? "N/A" : days_before_goal_date(appeal.receipt_date, docket),
        hearing_judge: hearing_judge,
        original_judge: appeal.cavc? ? ama_cavc_original_deciding_judge(appeal) : nil,
        veteran_file_number: appeal.veteran_file_number,
        veteran_name: appeal.veteran&.name.to_s,
        affinity_start_date: appeal.appeal_affinity&.affinity_start_date
      }
    end
  end

  def self.distribution_task_query(appeal)
    appeal.tasks
      .filter { |task| task.class == DistributionTask && task.status == Constants.TASK_STATUSES.assigned }
      .first&.assigned_at
  end

  def self.with_held_hearings(appeal)
    appeal.hearings
      .filter { |hearing| hearing.disposition = Constants.HEARING_DISPOSITION_TYPES.held }
      .first&.judge&.full_name
  end

  def self.target_distro_date(receipt_date, docket)
    if receipt_date.is_a?(String)
      receipt_date = Time.zone.parse(receipt_date).to_date
    elsif receipt_date.is_a?(Date) || receipt_date.is_a?(DateTime) || receipt_date.is_a?(Time)
      receipt_date = receipt_date.to_date
    else
      return nil
    end
    receipt_date + docket.docket_time_goal.to_i.days
  end

  def self.legacy_original_deciding_judge(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
    staff&.sdomainid || appeal["prev_deciding_judge"]
  end

  def self.legacy_original_deciding_judge_name(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
    deciding_judge_name = FullName.new(staff["snamef"], nil, staff["snamel"]).to_s
    deciding_judge_name.empty? ? nil : deciding_judge_name
  end

  def self.days_before_goal_date(receipt_date, docket)
    target_date = target_distro_date(receipt_date, docket)
    return nil if target_date.nil?

    target_date - docket.start_distribution_prior_to_goal.try(:value).to_i.days
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
