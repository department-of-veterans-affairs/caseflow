require "open3"
require "rainbow"

desc "shortcut to run all linting tools, at the same time."
task :security_caseflow do
  puts "running Brakeman security scan..."
  brakeman_result = ShellCommand.run(
    "brakeman --exit-on-warn --run-all-checks --confidence-level=2"
  )

  puts "running bundle-audit to check for insecure dependencies..."
  exit!(1) unless ShellCommand.run("bundle-audit update")

  # Set time zone when running in Circle CI environment.
  # TODO: Remove this when we stop calling Time.zone... below.
  Time.zone = "Eastern Time (US & Canada)"

  # Only ignore this vulnerability for a week.
  audit_cmd = "bundle-audit check --ignore CVE-2018-1000201"
  if Time.zone.local(2018, 9, 10) < Time.zone.today - 1.week
    audit_cmd = "bundle-audit check"
  end

  # ignore CVE-2018-1000201 (awaiting on https://github.com/rails/rails-html-sanitizer/pull/73)
  audit_cmd += " --ignore CVE-2018-16468"

  audit_result = ShellCommand.run(audit_cmd)

  puts "\n"
  if brakeman_result && audit_result
    puts Rainbow("Passed. No obvious security vulnerabilities.").green
  else
    puts Rainbow("Failed. Security vulnerabilities were found.").red
    exit!(1)
  end
end
