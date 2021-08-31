if ENV["RAILS_ENV"] == "test"
  SimpleCov.start do
    add_filter "app/services/test_data_service.rb"
    add_filter "lib/fakes"
    add_filter "lib/generators"
    add_filter "spec/support"
    add_filter "spec/rails_helper.rb"
    add_filter "spec/spec_helper.rb"
    add_filter "config/initializers"
    add_filter "config/environments/test.rb"
    add_filter "lib/tasks"
    add_filter "app/controllers/errors_controller.rb"
    add_filter "app/services/external_api/vbms_service.rb"
    add_filter "app/services/external_api/bgs_service.rb"
    add_filter "spec/factories"
    add_filter "spec/"
    add_filter "app/controllers/claim_review_controller.rb"
    add_filter "app/controllers/document_controller.rb"
    add_filter "app/controllers/hearings/hearing_day_controller.rb"
    add_filter "app/controllers/hearings/schedule_periods_controller.rb"
    add_filter "app/controllers/reader/documents_controller.rb"
    add_filter "app/controllers/sessions_controller.rb"
    add_filter "app/jobs/set_appeal_age_aod_job.rb"
    add_filter "app/jobs/update_appellant_representation_job.rb"
    add_filter "app/mappers/travel_board_schedule_mapper.rb"
    add_filter "app/models/api_status_alerts.rb"
    add_filter "app/models/appeal_history.rb"
    add_filter "app/models/appeal_series.rb"
    add_filter "app/models/decision_document.rb"
    add_filter "app/models/ramp_election_intake.rb"
    add_filter "app/models/task_filter.rb"
    add_filter "app/services/external_api/efolder_service.rb"
    add_filter "app/services/form8_pdf_service.rb"
    add_filter "db/seeds/intake.rb"
    add_filter "db/seeds/mtv.rb"
  end
  SimpleCov.coverage_dir ENV["COVERAGE_DIR"] || nil
  SimpleCov.command_name ENV["TEST_SUBCATEGORY"] || "all"
  if ENV["CIRCLE_NODE_INDEX"]
    SimpleCov.command_name "RSpec" + ENV["CIRCLE_NODE_INDEX"]
  end
end

