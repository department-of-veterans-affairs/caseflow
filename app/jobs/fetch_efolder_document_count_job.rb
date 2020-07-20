# frozen_string_literal: true

class FetchEfolderDocumentCountJob < CaseflowJob
  queue_with_priority :high_priority
  application_attr :queue

  def perform(file_number:, user:)
    RequestStore.store[:current_user] = user

    doc_count = ExternalApi::EfolderService.fetch_document_count(file_number, user)

    datadog_report_runtime(metric_group_name: "efolder_fetch_document_count")

    doc_count
  end
end
