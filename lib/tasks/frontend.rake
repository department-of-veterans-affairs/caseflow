# frozen_string_literal: true

require "rainbow"

desc "Runs the frontend React tests"
task :jstests do
  jest_karma_result = ShellCommand.run("cd ./client && yarn run test")

  if jest_karma_result
    puts Rainbow("Passed. All frontend react tests look good").green
  else
    puts Rainbow("Failed. Please check jest and karma tests in client/test").red
    exit(1)
  end
end
