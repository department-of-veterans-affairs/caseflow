# frozen_string_literal: true

# rubocop:disable Rails/ApplicationMailer
##
# TranscriptionFileIssuesMailer:
# - Generate emails from the templates in app/views/transcription_file_issues
##
class TranscriptionFileIssuesMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "transcription_file_issues_mailer"

  # Purpose: Builds email from view in app/views/transcription_file_issues_mailer/issue_notification
  #
  # Params: details - Hash of key-value pairs required to populate email template:
  #                     - error: { type: string, explanation: string }
  #                              - type: to render subject in #build_subject
  #                              - explanation: "Caseflow attempted to #{explanation} and received a fatal error."
  #                     - provider: string, to build subject and closing statement in #build_outro
  #                     - docket_number: string, optional, but if present renders in subject
  #                     - appeal_id: string, optional, but if present renders Case Details link
  #
  #                 - Optionally, any additional key-value pairs are iterated over and included in body as bullets
  #                   according to following formats:
  #                     - key: value => <li>key.to_s: value</li>
  #                     - key: { link: value } => <li><a href=value>key.to_s</a></li>
  #                     - key: { nested_key_1: value_1, nested_key_2: value_2 } =>
  #                            <li>key:
  #                              <ul>
  #                                <li>nested_key_1.to_s: value_1</li>
  #                                  <li>nested_key_2.to_us: value 2</li>
  #                              </ul>
  #                            </li>
  #
  def issue_notification(details)
    @details = details
    build_mailer_params

    mail(subject: build_subject, **mailer_config[:emails])
  end

  private

  def build_mailer_params
    @provider = @details.delete(:provider)
    @details[:case_details] = build_case_details_link(@details.delete(:appeal_id))
    @error_type = @details[:error][:type]
    @explanation = @details.delete(:error)&.dig(:explanation)
    @outro = build_outro
  end

  def build_case_details_link(appeal_id)
    return unless appeal_id

    { link: mailer_config[:base_url] + "/queue/appeals/#{appeal_id}" }
  end

  def build_subject
    provider = @provider ? " #{@provider.titlecase}" : ""
    docket_number = @details[:docket_number] ? " #{@details[:docket_number].titlecase}" : ""
    "File #{@error_type.titlecase} Error -" + provider + docket_number
  end

  def mailer_config
    case Rails.deploy_env
    when :development, :test
      { base_url: non_external_link,
        emails: { to: "Caseflow@test.com" } }
    when :uat
      { base_url: "https://appeals.cf.uat.ds.va.gov",
        emails: { to: "BID_Appeals_UAT@bah.com" } }
    when :prodtest
      { base_url: "https://appeals.cf.prodtest.ds.va.gov",
        emails: { to: "VHACHABID_Appeals_ProdTest@va.gov" } }
    when :preprod
      { base_url: "https://appeals.cf.preprod.ds.va.gov" }
    when :prod
      { base_url: "https://appeals.cf.ds.va.gov",
        emails: { to: "BVAHearingTeam@VA.gov",
                  cc: "OITAppealsHelpDesk@va.gov" } }
    end
  end

  # The link for the case details page when not in prod or uat
  def non_external_link
    # Rails.deploy_env returns :development for both development and demo envs, use ENV["DEPLOY_ENV"]
    return "https://demo.appeals.va.gov" if ENV["DEPLOY_ENV"] == "demo"

    "localhost:3000"
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
