require "rainbow"

CODE_COVERAGE_THRESHOLD = 90

task(:default).clear
task default: ["ci:warning", :spec, "ci:other"]

namespace :ci do
  desc "Warns against running the tests in serial"
  task :warning do
    puts Rainbow("Warning! You are running the tasks in serial which is very slow.").red
    puts Rainbow("Please try `rake ci:all` to run the tests faster in parallel").red
  end

  desc "Runs all the continuous integration scripts"
  task all: ["spec:parallel", "ci:other"]

  task default: :all

  desc "Run all non-spec CI scripts"
  task other: %w(ci:verify_code_coverage lint security konacha:run mocha)

  desc "Verify code coverge (via simplecov) after tests have been run in parallel"
  task :verify_code_coverage do
    puts "\nVerifying code coverage"
    require "simplecov"

    result = SimpleCov::ResultMerger.merged_result

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

  desc "Verify code coverge (via simplecov) on travis, skips if testing is incomplete"
  task :travis_verify_code_coverage do
    puts "\nVerifying code coverage"
    require "simplecov"

    test_categories = %w(unit api certification dispatch reader other)

    merged_results = test_categories.inject({}) do |merged, category|
      path = File.join("coverage/", ".#{category}.resultset.json")

      unless File.exist?(path)
        puts Rainbow("Missing code coverage result for #{category} tests. Testing isn't complete.").yellow
        exit!(0)
      end

      json = JSON.parse(File.read(path))
      SimpleCov::RawCoverage.merge_resultsets(merged, json[category]["coverage"])
    end

    result = SimpleCov::Result.new(merged_results)

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
