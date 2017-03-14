require "open3"
require "rainbow"

desc "shortcut to run all linting tools, at the same time."
task(:lint).clear
task :lint do
  puts "running scss-lint..."
  scss_result = ShellCommand.run("scss-lint --color")

  opts = ENV["CI"] ? "" : "--auto-correct"
  puts "running rubocop..."
  rubocop_result = ShellCommand.run("rubocop #{opts} --color")

  if defined? JRUBY_VERSION
    # fake a passing result
    jshint_result = true
  else
    puts "\nrunning jshint..."
    jshint_result = ShellCommand.run("rake jshint")
  end

  puts "\nrunning eslint..."
  eslint_cmd = ENV["CI"] ? "lint" : "lint:fix"
  eslint_result = ShellCommand.run("npm run #{eslint_cmd}")

  puts "\n"
  if scss_result && rubocop_result && jshint_result && eslint_result
    puts Rainbow("Passed. Everything looks stylish!").green
  else
    puts Rainbow("Failed. Linting issues were found.").red
    exit!(1)
  end
end
