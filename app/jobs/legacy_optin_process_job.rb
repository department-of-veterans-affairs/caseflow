# This job will call perform! on a LegacyIssueOptin
class LegacyOptinProcessJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(legacy_optin)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    begin
      legacy_optin.perform!
    rescue BadThing => err # TODO: define exceptions
      legacy_optin.update_error!(err.to_s)
      Raven.capture_exception(err)
    end
  end
end
