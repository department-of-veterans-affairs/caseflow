class WorkQueue::CavcDispositionsToReasonSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :cavc_dashboard_dispositions_id
  attribute :decision_reason_id
  attribute :basis_for_selection_id
end
