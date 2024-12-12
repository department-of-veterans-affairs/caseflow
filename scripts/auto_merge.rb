require "octokit"
require "net/http"
require "json"

MAX_FAILURE_COUNT = 5
CI_SUCCESS_STATUS = "success".freeze
CI_FAILURE_STATUS = "failure".freeze
CI_PENDING_STATUS = "pending".freeze
CI_ERROR_STATUS = "error".freeze

# TODO: Set up GitHub API token
GITHUB_TOKEN = ENV["GITHUB_TOKEN"] || "github_token"
REPO = "department-of-veterans-affairs/caseflow".freeze

# Email configuration
# TODO: to email address needs to be different
EMAIL_FROM = "caseflow_ci@caseflow.com".freeze
EMAIL_TO = "hughes_raymond@ne.bah.com".freeze

# TODO: Maybe Matt or Craig iknow this?
SMTP_SERVER = "".freeze
SMTP_PORT = 587
SMTP_USERNAME = "".freeze
SMTP_PASSWORD = "".freeze

# List of PR numbers to merge in specified order
# When ready to merge just add the PR numbers here
PR_LIST = [22833].freeze

# Initialize Octokit client
client = Octokit::Client.new(access_token: GITHUB_TOKEN)
client.auto_paginate = true

# PRs that fail > 5 times, skip and send an email to Tech Leads to manually merge
def send_email(subject, body)
  message = <<~MESSAGE_END
    From: Auto-Merge Script <#{EMAIL_FROM}>
    To: Tech Lead Team <#{EMAIL_TO}>
    Subject: #{subject}
    #{body}
  MESSAGE_END
  Net::SMTP.start(SMTP_SERVER, SMTP_PORT, "localhost", SMTP_USERNAME, SMTP_PASSWORD, :login) do |smtp|
    smtp.send_message(message, EMAIL_FROM, EMAIL_TO)
  end
  puts "Email sent: #{subject}"
end

def check_ci_status(sha)
  # Get commit statuses
  statuses = client.statuses(REPO, sha)
  latest_status = statuses.first
  return "error" if latest_status.nil?

  # Return the CI state ('success', 'failure', or 'pending')
  latest_status[:state]
end

# We want this to automatically rerun failed flaky tests.
def rerun_failed_tests(sha)
  # Rerun workflow via GitHub Actions API
  uri = URI("https://api.github.com/repos/#{REPO}/actions/runs/#{sha}/rerun")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request["Authorization"] = "token #{GITHUB_TOKEN}"
  response = http.request(request)
  unless response.code.to_i == 201
    puts "Failed to rerun tests for commit #{sha}. Manual intervention required."
  end
end

# rubocop:disable Metrics/MethodLength
def pull_request_handler(pr_number)
  pull_request = client.pull_request(REPO, pr_number)
  sha = pull_request[:head][:sha]
  puts "Checking status of PR ##{pr_number}..."

  # Check CI status
  status = check_ci_status(sha)

  if status == CI_SUCCESS_STATUS
    handle_merging(pr_number)
  elsif status == CI_FAILURE_STATUS
    puts "CI tests failed for PR ##{pr_number}. Rerunning tests."
    failure_count[pr_number] += 1

    if failure_count[pr_number] > MAX_FAILURE_COUNT
      subject = "Tests Failed More than #{MAX_FAILURE_COUNT} Times for PR ##{pr_number}"
      body = "The tests for PR ##{pr_number} have failed more than #{MAX_FAILURE_COUNT} times. Manual merging required."
      send_email(subject, body)
      return # Do not rerun tests if the failure count exceeds 5
    end

    rerun_failed_tests(sha)
    pull_request_handler(pr_number)
  elsif status == CI_ERROR_STATUS
    # something is not right....bail completely
    fail StandardError, "Script failed to run"
  else
    puts "CI tests are still pending for PR ##{pr_number}. Will retry after some time."

    # Currently our CI pipeline takes right around 30 minutes. ⏳
    # We will do the inital check and if its pending lets wait for 5 minutes
    # The reason for 5 minutes is because its relatively inexpensive operation to just check the status.
    # If we waited for 30 minutes and one test was still pending for example,
    # then it would wait an additional 30 minutes and this is all for nothong  🤷
    sleep(300) # 60 * 5

    pull_request_handler(pr_number)
  end
end
# rubocop:enable Metrics/MethodLength

# Currently we merge the branch to its base. This could get dangerous without any checks
def handle_merging(pr_number)
  puts "CI tests passed for PR ##{pr_number}. Attempting to merge."
  client.merge_pull_request(REPO, pr_number)
  puts "PR ##{pr_number} merged successfully."

  # Send email notification after successful merge
  subject = "PR ##{pr_number} Merged Successfully"
  body = "The pull request ##{pr_number} has been successfully merged into the #{pull_request[:base][:ref]} branch."
  send_email(subject, body)
end

# Loops over sorted array and merges the PR
def process_pr_queue(pr_list)
  pr_list.each do |pr_number|
    pull_request_handler(pr_number)
  end
end

# Kick-off script
if __FILE__ == $PROGRAM_NAME
  process_pr_queue(PR_LIST)
end
