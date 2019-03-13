# frozen_string_literal: true

require "open3"
require "rainbow"
require "date"

desc "shortcut to run all security tools, at the same time."
task :security_caseflow do
  $stdout.sync = true
  puts "running Brakeman security scan..."
  brakeman_result = ShellCommand.run(
    "brakeman --exit-on-warn --run-all-checks --confidence-level=2"
  )

  puts "running bundle-audit to check for insecure dependencies..."
  exit!(1) unless ShellCommand.run("bundle-audit update")

  snoozed_cves = [
    # Example:
    # { cve_name: "CVE-2018-1000201", until: Time.zone.local(2018, 9, 10) }
    { cve_name: "CVE-2019-5420", until: Date.new(2019, 03, 30) }
  ]

  alerting_cves = snoozed_cves
    .select { |cve| cve[:until] >= Date.today }
    .map { |cve| cve[:cve_name] }

  audit_cmd = "bundle-audit check --ignore=#{alerting_cves.join(' ')}"

  puts audit_cmd

  audit_result = ShellCommand.run(audit_cmd)

  puts "\n"
  if brakeman_result && audit_result
    puts Rainbow("Passed. No obvious security vulnerabilities.").green
  else
    puts Rainbow(
      "Failed. Security vulnerabilities were found. Find the dependency in Gemfile.lock, "\
      "then specify a safe version of the dependency in the Gemfile (preferred) or "\
      "snooze the CVE in security.rake for a week."
    ).red
    puts Rainbow(
      "See https://github.com/department-of-veterans-affairs/caseflow/pull/7639 for an example."
    ).red
    exit!(1)
  end
end
