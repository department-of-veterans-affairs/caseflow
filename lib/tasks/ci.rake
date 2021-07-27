# frozen_string_literal: true

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

  desc "Verify code coverage (via simplecov) after tests have been run in parallel"
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

  desc "Verify code coverage on CircleCI "
  task :circleci_verify_code_coverage do
    require "simplecov"
    $stdout.sync = true

    api_url = "https://circleci.com/api/v1.1/project/github/" \
              "#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/" \
              "#{ENV['CIRCLE_BUILD_NUM']}/artifacts"
    coverage_dir = "~/coverage/combined"
    SimpleCov.coverage_dir(coverage_dir)
    SimpleCov.load_profile("rails")

    # Set the merge_timeout very large so that we don't exclude results
    # just because the runs took a long time.
    SimpleCov.merge_timeout(3600 * 24 * 30)
    artifacts = JSON.parse(URI.parse(api_url).read)
    artifact_urls = artifacts.map { |a| a["url"] }
    resultset_urls = artifact_urls.select { |u| u.end_with?(".resultset.json") }
    resultsets = resultset_urls.map do |u|
      puts "URI: #{u}"
      c = URI.parse(u).read
      JSON.parse(c)
    end

    # SimpleCov doesn't really support merging results after the fact.
    # [mattw 2021: It kind of does with .collate but it's not an easy change.]
    # This construct manually re-creates the SimpleCov merge process
    # NOTE: we use exit! in order to avoid SimpleCov's at_exit handler
    # which will print misleading results.
    results = resultsets.map do |resultset|
      SimpleCov::Result.from_hash(resultset)
    end
    result = SimpleCov::ResultMerger.merge_coverage(*results)
    SimpleCov::ResultMerger.store_result(result)
    if result.covered_percentages.empty?
      puts Rainbow("No valid coverage results were found").red
      exit!(1)
    end
    # This prints code coverage statistics as a side effect, which we want
    # in the build log.
    result.format!

    File.open("#{ENV['COVERAGE_DIR']}/merged_results.json", "w") do |f|
      f.write(JSON.pretty_generate(result.to_hash))
    end

    undercovered_files = result.covered_percentages.zip(result.filenames).select do |c|
      c.first < CODE_COVERAGE_THRESHOLD
    end

    if !undercovered_files.empty?
      puts Rainbow("The expected minimum coverage per file is: #{CODE_COVERAGE_THRESHOLD}%").red
      puts Rainbow("File Name - Percentage").red

      undercovered_files.map do |undercovered_file|
        puts Rainbow("#{undercovered_file.second} - #{undercovered_file.first.to_i}%").red
      end

      exit!(1)
    else
      puts Rainbow("Code coverage threshold met\n").green
      exit!(0)
    end
  end
end
