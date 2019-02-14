require "open3"
require "rainbow"

desc "shortcut to run all linting tools, at the same time."
task(:lint).clear
task :lint do
  puts "running scss-lint..."
  scss_result = ShellCommand.run("scss-lint --color")

  opts = ENV["CI"] ? "--parallel" : "--auto-correct"
  puts "running rubocop..."
  rubocop_result = ShellCommand.run("rubocop #{opts} --color")

  puts "running fasterer..."
  fasterer_result = ShellCommand.run("bundle exec fasterer")

  puts "\nrunning eslint..."
  eslint_cmd = ENV["CI"] ? "lint" : "lint:fix"
  eslint_result = ShellCommand.run("cd ./client && yarn run #{eslint_cmd}")

  puts "\nrunning Flow..."
  flow_result = ShellCommand.run("cd ./client && yarn run flow check")

  puts "\n"
  if scss_result && rubocop_result && eslint_result && flow_result && fasterer_result
    puts Rainbow("Passed. Everything looks stylish! " \
      "But there may have been auto-corrections that you now need to check in.").green
  else
    puts Rainbow("Failed. Linting issues were found.").red
    exit!(1)
  end
end
