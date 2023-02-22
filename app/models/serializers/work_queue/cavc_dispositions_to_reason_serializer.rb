# frozen_string_literal: true

class WorkQueue::CavcDispositionsToReasonSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :cavc_dashboard_disposition
  attribute :cavc_decision_reason
  attribute :cavc_selection_bases
end
