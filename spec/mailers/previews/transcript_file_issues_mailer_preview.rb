# frozen_string_literal: true

# preview mailer html [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/send_issue_details]
# [http://localhost:3000/rails/mailers/transcript_file_issues_mailer/webex_recording_list_issues]

class TranscriptFileIssuesMailerPreview < ActionMailer::Preview
  def send_issue_details
    details = {
      action: "ACTION",
      filetype: "VTT",
      direction: "Download",
      provider: "Webex",
      docket_number: "123456",
      times: "TIME_OR_LINK",
      api_call: "www.webext.test.com",
      response: {
        thing1key: "thing1value",
        thing2key: "thing2value",
        thing3key: "thing3value"
      },
      error: "some error"
    }
    appeal_id = "APPEAL_ID"
    TranscriptFileIssuesMailer.send_issue_details(details, appeal_id)
  end

  def webex_recording_list_issues
    details = {
      action: "ACTION",
      provider: "webex"
    }
    TranscriptFileIssuesMailer.webex_recording_list_issues(details)
  end
end
