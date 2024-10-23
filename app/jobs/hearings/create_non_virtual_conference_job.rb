# frozen_string_literal: true

# This job creates a Webex conference & link for a non virtual hearing

class Hearings::CreateNonVirtualConferenceJob < CaseflowJob
  # We are not using ensure_current_user_is_set because of some
  # potential for rollbacks if the set user is not the system user

  queue_with_priority :high_priority
  application_attr :hearing_schedule

  attr_reader :hearing

  # Retry if Webex returns an invalid response.
  retry_on(Caseflow::Error::WebexApiError, wait: :exponentially_longer) do |job, exception|
    job.log_error(exception)
  end

  def perform(hearing:)
    RequestStore.store[:current_user] = User.system_user
    WebexConferenceLink.find_or_create_by!(
      hearing: hearing,
      created_by: hearing.created_by,
      updated_by: hearing.created_by
    )
  end
end
