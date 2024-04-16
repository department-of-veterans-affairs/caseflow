# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
##
# TranscriptionFileIssuesMailerr will:
# - Generate emails from the templates in app/views/transcription_file_issues
##
class TranscriptionFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "transcription_file_issues_mailer"

  # Builds email from view in app/views/transcription_file_issues_mailer/issue_notification
  def issue_notification(details)
    @details = details
    build_mailer_params

    mail(subject: build_subject, **mailer_config[:emails])
  end

  private

  def build_mailer_params
    @provider ||= @details.delete(:provider)
    @details[:case_details] = build_case_details_link(@details.delete(:appeal_id))
    @error_type ||= @details[:error][:type]
    @explanation ||= @details.delete(:error)&.dig(:explanation)
    @outro ||= build_outro
  end

  def build_case_details_link(appeal_id)
    return unless appeal_id

    { link: mailer_config[:base_url] + "appeals/#{appeal_id}" }
  end

  def build_subject
    provider = @provider ? " #{@provider.titlecase}" : ""
    docket_number = @details[:docket_number] ? " #{@details[:docket_number].titlecase}" : ""
    "File #{@error_type.titlecase} Error -" + provider + docket_number
  end

  def mailer_config
    case Rails.deploy_env
    when :development, :demo, :test
      { base_url: non_external_link,
        emails: { to: "Caseflow@test.com" } }
    when :uat
      { base_url: "https://appeals.cf.uat.ds.va.gov/queue/",
        emails: { to: "BID_Appeals_UAT@bah.com" } }
    when :prodtest
      { base_url: "https://appeals.cf.prodtest.ds.va.gov/queue/" }
    when :preprod
      { base_url: "https://appeals.cf.preprod.ds.va.gov/queue/" }
    when :prod
      { base_url: "https://appeals.cf.ds.va.gov/queue/",
        emails: { to: "BVAHearingTeam@VA.gov",
                  cc: "OITAppealsHelpDesk@va.gov" } }
    end
  end

  # The link for the case details page when not in prod or uat
  def non_external_link
    return "https://demo.appeals.va.gov/" if Rails.deploy_env == :demo

    "localhost:3000/queue/"
  end

  def build_outro
    return "continued communication between Caseflow and #{@provider.titlecase}" if issue_with_conference_provider?

    "Caseflow has been supplied with the necessary files"
  end

  def issue_with_conference_provider?
    %w[webex].include?(@provider)
  end
end
# rubocop:enable Rails/ApplicationMailer
