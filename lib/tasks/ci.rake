require "rainbow"

CODE_COVERAGE_THRESHOLD = 90

task default: "ci:all"

namespace :ci do
  desc "Runs all the continuous integration scripts"
  task all: [:lint, :security, :spec, :sauceci, "konacha:run", :mocha]

  desc "Run all non-spec CI scripts"
  task "all-other" => %w(ci:verify_code_coverage lint security konacha:run mocha)

  desc "Verify code coverge via simplecov, after tests have been run in parallel"
  task :verify_code_coverage do
    require 'simplecov'
    resultset = SimpleCov::ResultMerger.resultset
    results = []
    resultset.each do |command_name, data|
      results << SimpleCov::Result.from_hash(command_name => data)
    end

    merged = {}
    results.each do |result|
      merged = result.original_result.merge_resultset(merged)
    end
    result = SimpleCov::Result.new(merged)

    if result.covered_percentages.any? { |c| c < CODE_COVERAGE_THRESHOLD }
      puts Rainbow("File #{result.least_covered_file} is only #{result.covered_percentages.min}% covered. This is below the expected minimum coverage per file of #{CODE_COVERAGE_THRESHOLD}%.").red
      exit!(1)
    else
      puts Rainbow("Code coverage threshold met").green
    end
  end
end


