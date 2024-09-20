if ENV["RAILS_ENV"] == "test"
  require "simplecov"
  require "simplecov_lcov_formatter"

  # This ensures the command name is unique for each CI node
  SimpleCov.command_name "RSpec-#{ENV['GHA_NODE_INDEX']}" if ENV['GHA_NODE_INDEX']
  # Specify the coverage directory
  SimpleCov.coverage_dir "coverage/coverage-#{ENV['GHA_NODE_INDEX']}"

  # Configure the LCOV formatter
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

  # Set the formatters for both HTML and LCOV reports
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
  puts "SimpleCov is running on node #{ENV['GHA_NODE_INDEX']} and storing coverage in coverage/coverage-#{ENV['GHA_NODE_INDEX']}"

  # Define which files to filter out from coverage reports
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
    add_filter "app/services/redistributed_case.rb"
    add_filter "spec/factories"
    add_filter "spec/"
  end

  # Store result for merging
  SimpleCov.at_exit do
    SimpleCov.result.format!
    if ENV['CI']
      SimpleCov::ResultMerger.store_result(SimpleCov.result)
    end
  end
else
  puts "SimpleCov is not running in CI or no node index is found"
end
