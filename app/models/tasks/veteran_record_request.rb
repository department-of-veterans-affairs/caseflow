# frozen_string_literal: true

##
# Created whenever an Appeal request issue has a benefit_type that is not compensation or pension.

class VeteranRecordRequest < DecisionReviewTask
  include BusinessLineTaskConcern

  def label
    "Record Request"
  end

  def serializer_class
    ::WorkQueue::VeteranRecordRequestSerializer
  end

  # this creates a method called appeal_ui_hash
  delegate :ui_hash, to: :appeal, prefix: true
end
