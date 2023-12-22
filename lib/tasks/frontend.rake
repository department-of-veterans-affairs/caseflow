# frozen_string_literal: true

require "rainbow"

desc "Runs the frontend React tests"
task js_tests: :environment do
  js_test_results = ShellCommand.run("cd ./client && yarn run test")

  if js_test_results
    puts Rainbow("Passed. All frontend react tests look good").green
  else
    puts Rainbow("Failed. Please check the jest tests in client/test").red
    exit(1)
  end
end
