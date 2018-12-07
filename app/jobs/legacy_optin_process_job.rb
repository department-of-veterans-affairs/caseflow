# This job will call perform! on a LegacyIssueOptin
class LegacyOptinProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(legacy_optin)
    # restore whatever the user was when we finish, in case we are not running async (as during tests)
    current_user = RequestStore.store[:current_user]
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    return_value = nil

    begin
      return_value = legacy_optin.perform!
    rescue StandardError => err # TODO: define exceptions
      legacy_optin.update_error!(err.to_s)
      Raven.capture_exception(err)
    end

    RequestStore.store[:current_user] = current_user
    return_value
  end
end
