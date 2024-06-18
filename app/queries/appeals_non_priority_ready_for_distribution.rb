# frozen_string_literal: true

class AppealsNonPriorityReadyForDistribution < AppealsReadyForDistribution
  # define CSV headers and use this to pull fields to maintain order for Non Priority
  NON_PRIORITY_HEADERS = {
    docket_number: "Docket Number",
    docket: "Docket",
    aod: "AOD",
    cavc: "CAVC",
    receipt_date: "Receipt Date",
    assigned_at: "Assigned at",
    ready_for_distribution_at: "Ready for Distribution at",
    target_distro_date: "Target Distro Date",
    days_before_goal_date: "Days Before Goal Date",
    hearing_judge: "Hearing Judge",
    veteran_file_number: "Veteran File number",
    veteran_name: "Veteran",
    affinity_start_date: "Affinity Start Date"
  }.freeze

  def self.generate_rows(record)
    NON_PRIORITY_HEADERS.keys.map { |key| record[key] }
  end

  def self.process
    # Convert results to CSV format

    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << NON_PRIORITY_HEADERS.values

      # Iterate through results and add each row to CSV
      ready_appeals.each do |record|
        csv << generate_rows(record)
      end
    end
  end

  def self.ready_appeals
    docket_coordinator = DocketCoordinator.new

    docket_coordinator.dockets
      .flat_map do |sym, docket|
        if sym == :legacy
          []
        else
          appeals = docket.ready_to_distribute_appeals.nonpriority
          ama_rows(appeals, docket, sym)
        end
      end
  end

  def self.ama_rows(appeals, docket, sym)
    appeals.map do |appeal|
      # This comes from the DistributionTask's assigned_at date
      ready_for_distribution_at = distribution_task_query(appeal)
      # only look for hearings that were held
      hearing_judge = with_held_hearings(appeal)
      {
        docket_number: appeal.docket_number,
        docket: sym.to_s,
        aod: appeal.aod,
        cavc: appeal.cavc,
        receipt_date: appeal.receipt_date,
        assigned_at: "assigned_at",
        ready_for_distribution_at: ready_for_distribution_at,
        target_distro_date: target_distro_date(appeal.receipt_date, docket),
        days_before_goal_date: days_before_goal_date(appeal.receipt_date, docket),
        hearing_judge: hearing_judge,
        veteran_file_number: appeal.veteran_file_number,
        veteran_name: appeal.veteran&.name.to_s,
        affinity_start_date: "NA"
      }
    end
  end
end
