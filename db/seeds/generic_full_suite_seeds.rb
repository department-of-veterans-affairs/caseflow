# frozen_string_literal: true
GENERIC_FULL_SUITE_SEEDS = [
  "tasks",
  "hearings",
  "intake",
  "substitutions",
  "cavc_ama_appeals"
  # "sanitized_json_seeds",
  # "veterans_health_administration",
  # "mtv",
  # "education",
  # "priority_distributions",
  # "test_case_data",
  # "case_distribution_audit_lever_entries",
  # "notifications",
  # "cavc_dashboard_data",
  # "vbms_ext_claim",
  # "cases_tied_to_judges_no_longer_with_board",
  # "vha_change_history",
  # "static_test_case_data",
  # "static_dispatched_appeals_test_data",
  # "remanded_ama_appeals",
  # "remanded_legacy_appeals",
  # "populate_from_caseflow"
]
# because db/seeds is not in the autoload path, we must load them explicitly here
# base.rb needs to be loaded first because the other seeds inherit from it
require Rails.root.join("db/seeds/base.rb").to_s

class GenericFullSuiteSeeds

  def initialize
    @filtered_files = Dir[Rails.root.join("db/seeds/*.rb")].sort.select do |file|
      GENERIC_FULL_SUITE_SEEDS.include?(File.basename(file, ".rb"))
    end
    msg = "filtered_files: #{@filtered_files}"
    Rails.logger.debug(msg)
  end
  # In development environments this log goes to
  # caseflow/log/development.log
  def call_and_log_seed_step(step)
    msg = "Starting seed step #{step} at #{Time.zone.now.strftime('%m/%d/%Y %H:%M:%S')}"
    Rails.logger.debug(msg)

    if step.is_a?(Symbol)
      send(step)
    else
      step.new.seed!
    end

    msg = "Finished seed step #{step} at #{Time.zone.now.strftime('%m/%d/%Y %H:%M:%S')}"
    Rails.logger.debug(msg)
  end

  def seed!
    RequestStore[:current_user] = User.system_user

    @filtered_files.each do |file|
      class_name = "Seeds::#{File.basename(file, '.rb').camelize}".constantize
      call_and_log_seed_step(class_name)
    end
  end
end

