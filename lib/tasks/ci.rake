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
  task other: %w[ci:verify_code_coverage lint security mocha]

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

  desc "Verify code coverage (via simplecov) on travis, skips if testing is incomplete"
  task :travis_verify_code_coverage do
    puts "\nVerifying code coverage"
    require "simplecov"

    test_categories = %w[unit api certification dispatch reader other queue]

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

  desc "Verify code coverage on CircleCI "
  task :circleci_verify_code_coverage do
    require "simplecov"

    api_url = "https://circleci.com/api/v1.1/project/github/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/#{ENV['CIRCLE_BUILD_NUM']}/artifacts?circle-token=#{ENV['CIRCLE_TOKEN']}"
    coverage_dir = "/tmp/coverage"
    SimpleCov.coverage_dir(coverage_dir)

    artifacts = JSON.parse(open(api_url).read)
    artifact_urls = artifacts.map { |a| a["url"] }
    resultset_urls = artifact_urls.select { |u| u.end_with?(".resultset.json") }
    resultsets = resultset_urls.map do |u|
      c = open(u + "?circle-token=#{ENV['CIRCLE_TOKEN']}").read
      JSON.parse(c)
    end
    merged_results = resultsets.reduce({}) do |merged, r|
      _, d = r.first
      SimpleCov::RawCoverage.merge_resultsets(merged, d["coverage"])
    end
    result = SimpleCov::Result.new(merged_results)
    #merged_resultset = resultsets.reduce({}) do |merged, r|
      #SimpleCov::RawCoverage.merge_resultsets(merged, r["all"]["coverage"])
    #end
    #puts(merged_resultset)
    #result = SimpleCov::Result.new(merged_resultset)
    # coverage.each_with_index do |resultset, i|
    #   resultset.each_value do |data|
    #     result = SimpleCov::Result.from_hash(["command", i].join => data)
    #     SimpleCov::ResultMerger.store_result(result)
    #   end
    # end
    # result = SimpleCov::ResultMerger.merged_result
    # result.command_name = "RSpec"

    # puts(a.to_s)
    #   .each_with_index do |resultset, i|
    #   resultset.each_value do |data|
    #     result = SimpleCov::Result.from_hash(["command", i].join => data)
    #     SimpleCov::ResultMerger.store_result(result)
    #   end
    # end
    #
    #
    if result.covered_percentages.empty?
      puts Rainbow("No valid coverage results were found").red
      exit!(1)
    end
    if result.covered_percentages.any? { |c| c < CODE_COVERAGE_THRESHOLD }
      puts Rainbow("File #{result.least_covered_file} is only #{result.covered_percentages.min.to_i}% covered.\
                    This is below the expected minimum coverage per file of #{CODE_COVERAGE_THRESHOLD}%\n").red
      exit!(1)
    else
      puts Rainbow("Code coverage threshold met\n").green
    end
  end
end
