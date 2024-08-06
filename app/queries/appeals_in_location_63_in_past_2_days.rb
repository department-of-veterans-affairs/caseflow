# frozen_string_literal: true

class AppealsInLocation63InPast2Days
    HEADERS = {
    docket_number: "Docket Number",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    ready_for_distribution_at: "Ready for Distribution at",
    veteran_file_number: "Veteran File number",
    veteran_name: "Veteran",
    hearing_judge: "Most Recent Hearing Judge",
    deciding_judge: "Most Recent Deciding Judge",
    affinity_start_date: "Affinity Start Date",
    moved_date_time: "Date/Time Moved",
    bfcurloc: "BFCURLOC"
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
      loc_63_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  def self.loc_63_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        if sym == :legacy
          appeals = docket.loc_63_appeals
          legacy_rows(appeals, docket, sym)
        else
          []
          # ama_rows(appeals, docket, sym)
        end
      end
  end

  def self.legacy_rows(appeals, docket, sym)
    appeals.map do |appeal|
      veteran_name = FullName.new(appeal["snamef"], nil, appeal["snamel"]).to_s
      vlj_name = FullName.new(appeal["vlj_namef"], nil, appeal["vlj_namel"]).to_s
      hearing_judge = vlj_name.empty? ? nil : vlj_name
      deciding_judge = appeal["bfmemid"].blank? ? nil : legacy_original_deciding_judge(appeal)
      moved_date_time = "TODO"
      appeal_affinity = AppealAffinity.find_by(case_id: appeal["bfkey"], case_type: "VACOLS::Case")

      {
        docket_number: appeal["tinum"],
        aod: appeal["aod"] == 1,
        cavc: appeal["cavc"] == 1,
        receipt_date: appeal["bfd19"],
        ready_for_distribution_at: appeal["bfdloout"],
        veteran_file_number: appeal["ssn"] || appeal["bfcorlid"],
        veteran_name: veteran_name,
        hearing_judge: hearing_judge,
        deciding_judge: deciding_judge,
        affinity_start_date: appeal_affinity&.affinity_start_date,
        moved_date_time: appeal["bfdlocin"],
        bfcurloc: appeal["bfcurloc"]
      }
    end
  end

  def self.ama_rows(appeals, docket, sym)
    # appeals.map do |appeal|
      # This comes from the DistributionTask's assigned_at date
      # ready_for_distribution_at = distribution_task_query(appeal)
      # only look for hearings that were held
      # hearing_judge = with_held_hearings(appeal)
      # {
        # docket_number: appeal.docket_number,
        # docket: sym.to_s,
        # aod: appeal.aod,
        # cavc: appeal.cavc,
        # receipt_date: appeal.receipt_date,
        # ready_for_distribution_at: ready_for_distribution_at,
        # target_distro_date: target_distro_date(appeal.receipt_date, docket),
        # days_before_goal_date: days_before_goal_date(appeal.receipt_date, docket),
        # hearing_judge: hearing_judge,
        # veteran_file_number: appeal.veteran_file_number,
        # veteran_name: appeal.veteran&.name.to_s,
        # affinity_start_date: appeal.appeal_affinity&.affinity_start_date
      # }
    # end
  end

  def self.legacy_original_deciding_judge(appeal)
    staff = VACOLS::Staff.find_by(sattyid: appeal["bfmemid"])
    staff&.sdomainid || appeal["bfmemid"]
  end

end
