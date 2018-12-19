class ProcessDecisionDocumentJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(decision_document)
    RequestStore.store[:application] = "intake"
    RequestStore.store[:current_user] = User.system_user

    decision_document.process!
  end
end
