# This job runs Intake.complete! steps
class CompleteIntakeJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake
  attr_accessor :intake

  def perform(intake, request_issues, user = nil)
    RequestStore.store[:current_user] = user if user

    @intake = intake
    perform_intake(request_issues)
  end

  private

  def perform_intake(request_issues)
    # TODO: wrap this all in a transaction?
    intake.start_completion!
    detail.request_issues.destroy_all unless detail.request_issues.empty?
    detail.create_issues!(build_issues(request_issues))
    detail.update!(establishment_submitted_at: Time.zone.now)
    detail.process_end_product_establishments!
    intake.complete_with_status!(:success)
  end

  def detail
    intake.detail
  end

  def build_issues(request_issues_data)
    request_issues_data.map { |data| detail.request_issues.from_intake_data(data) }
  end
end
