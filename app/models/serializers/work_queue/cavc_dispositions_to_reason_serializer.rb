# frozen_string_literal: true

class WorkQueue::CavcDispositionsToReasonSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :cavc_dashboard_disposition_id
  attribute :cavc_decision_reason_id
  attribute :cavc_reasons_to_bases
end
