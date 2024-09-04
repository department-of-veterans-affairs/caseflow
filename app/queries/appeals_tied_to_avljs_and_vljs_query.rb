# frozen_string_literal: true

class AppealsTiedToAvljsAndVljsQuery
  # define CSV headers and use this to pull fields to maintain order

  HEADERS = {
    docket_number: "Docket number",
    docket: "Docket type",
    priority: "Priority",
    receipt_date: "Receipt Date",
    veteran_file_number: "File Number",
    veteran_name: "Veteran Name",
    vlj: "VLJ Name",
    hearing_judge: "Most-recent hearing judge",
    most_recent_signing_judge: "Most-recent judge who signed decision name (May be blank if no decision was signed)",
    bfcurloc: "Current Location"
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
      tied_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  # Uses DocketCoordinator to pull appeals ready for distribution
  # DocketCoordinator is used by Automatic Case Distribution so this will give us the most accurate list of appeals
  def self.tied_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
      if sym == :legacy
        appeals = docket.appeals_tied_to_avljs_and_vljs
        unique_appeals = legacy_rows(appeals, sym).uniq { |record| record[:docket_number] }

        unique_appeals
      else
        appeals = docket.tied_to_vljs(vlj_user_ids)

        ama_rows(appeals, sym)
      end
    end
  end

  def self.legacy_rows(appeals, sym)
    appeals.map do |appeal|
      calculated_values = calculate_field_values(appeal)
      {
        docket_number: appeal["tinum"],
        docket: sym.to_s,
        priority: appeal["priority"] == 1 ? "True" : "",
        receipt_date: appeal["bfd19"],
        veteran_file_number: calculated_values[:veteran_file_number],
        veteran_name: calculated_values[:veteran_name],
        vlj: calculated_values[:vlj],
        hearing_judge: calculated_values[:hearing_judge],
        most_recent_signing_judge: calculated_values[:most_recent_signing_judge],
        bfcurloc: calculated_values[:bfcurloc]
      }
    end
  end

  def self.ama_rows(appeals, sym)
    appeals.map do |appeal|
      # # This comes from the DistributionTask's assigned_at date
      # ready_for_distribution_at = distribution_task_query(appeal)
      # only look for hearings that were held
      hearing_judge = ama_hearing_judge(appeal)
      signing_judge = ama_cavc_original_deciding_judge(appeal)
      {
        docket_number: appeal.docket_number,
        docket: sym.to_s,
        priority: appeal.aod || appeal.cavc,
        receipt_date: appeal.receipt_date,
        veteran_file_number: appeal.veteran_file_number,
        veteran_name: appeal.veteran&.name.to_s,
        vlj: hearing_judge,
        hearing_judge: hearing_judge,
        most_recent_signing_judge: signing_judge,
        bfcurloc: nil
      }
    end
  end

  def self.vlj_user_ids
    staff_domainids = VACOLS::Staff.where("svlj in ('A','J') AND sactive in ('A','I') ")
      .pluck(:sdomainid)
      .uniq
      .compact

    User.where(css_id: staff_domainids).pluck(:id)
  end

  def self.calculate_field_values(appeal)
    vlj_name = get_vlj_name(appeal)
    prev_judge_name = get_prev_judge_name(appeal)
    vacols_case = VACOLS::Case.find_by(bfkey: appeal["bfkey"])
    veteran_record = VACOLS::Correspondent.find_by(stafkey: vacols_case.bfcorkey)
    {
      veteran_file_number: veteran_record.ssn || vacols_case&.bfcorlid,
      veteran_name: get_name_from_record(veteran_record),
      vlj: vlj_name,
      hearing_judge: vlj_name,
      most_recent_signing_judge: prev_judge_name,
      bfcurloc: vacols_case&.bfcurloc
    }
  end

  def self.get_vlj_name(appeal)
    if appeal["vlj"].nil?
      vlj_name = nil
    else
      vlj_record = VACOLS::Staff.find_by(sattyid: appeal["vlj"])
      vlj_name = get_name_from_record(vlj_record)
    end

    vlj_name
  end

  def self.get_prev_judge_name(appeal)
    if appeal["prev_deciding_judge"].nil?
      prev_judge_name = nil
    else
      prev_judge_record = VACOLS::Staff.find_by(sattyid: appeal["prev_deciding_judge"])
      prev_judge_name = get_name_from_record(prev_judge_record)
    end

    prev_judge_name
  end

  def self.get_name_from_record(record)
    FullName.new(record["snamef"], nil, record["snamel"]).to_s
  end

  def self.ama_hearing_judge(appeal)
    appeal.hearings
      .filter { |hearing| hearing.disposition = Constants.HEARING_DISPOSITION_TYPES.held }
      .first&.judge&.full_name
  end

  def self.ama_cavc_original_deciding_judge(appeal)
    return nil if appeal.cavc_remand.nil?

    source_appeal_id = CavcRemand.find_by(remand_appeal: appeal).source_appeal_id
    judge_css_id = Task.find_by(
      appeal_id: source_appeal_id,
      appeal_type: Appeal.name,
      type: JudgeDecisionReviewTask.name
    )&.assigned_to&.css_id

    User.find_by_css_id(judge_css_id)&.full_name
  end
end
