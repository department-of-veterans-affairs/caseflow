class WorkQueue::CavcDispositionsToReasonSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :cavc_dashboard_disposition
  attribute :decision_reason
  attribute :basis_for_selection
end
