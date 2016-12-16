require "rainbow"

CODE_COVERAGE_THRESHOLD = 90

namespace :ci do
  desc "Runs all the continuous integration scripts"
  task :all do
    Rake::Task["parallel:spec"].invoke(4) # 4 processes
    Rake::Task["ci:other"].invoke
  end

  task default: :all

  desc "Run all non-spec CI scripts"
  task other: %w(ci:verify_code_coverage lint security konacha:run mocha)

  desc "Verify code coverge (via simplecov) after tests have been run in parallel"
  task :verify_code_coverage do
    puts "\nVerifying code coverage"
    require "simplecov"

    resultset = SimpleCov::ResultMerger.resultset
    results = resultset.map do |command_name, data|
      SimpleCov::Result.from_hash(command_name => data)
    end

    merged = {}
    results.each do |result|
      merged = result.original_result.merge_resultset(merged)
    end
    result = SimpleCov::Result.new(merged)

    if result.covered_percentages.empty?
      puts Rainbow("No valid coverage results were found").red
      exit!(1)
    end

    # Rebuild HTML file with correct merged results
    result.format!

    if result.covered_percentages.any? { |c| c < CODE_COVERAGE_THRESHOLD }
      puts Rainbow("File #{result.least_covered_file} is only #{result.covered_percentages.min.to_i}% covered.\
                   This is below the expected minimum coverage per file of #{CODE_COVERAGE_THRESHOLD}%\n").red
      exit!(1)
    else
      puts Rainbow("Code coverage threshold met\n").green
    end
  end
end
