# frozen_string_literal: true

class WorkQueue::DocketSwitchSerializer
  include FastJsonapi::ObjectSerializer

  attribute :disposition
  attribute :docket_type
  attribute :receipt_date

  attribute :old_appeal_uuid do |object|
    object.old_docket_stream.uuid
  end
  attribute :new_appeal_uuid do |object|
    object.new_docket_stream&.uuid
  end
end
