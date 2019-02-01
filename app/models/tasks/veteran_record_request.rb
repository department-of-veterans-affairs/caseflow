class VeteranRecordRequest < GenericTask
  include BusinessLineTask

  def label
    "Record Request"
  end

  def serializer_class
    ::WorkQueue::VeteranRecordRequestSerializer
  end

  # this creates a method called appeal_ui_hash
  delegate :ui_hash, to: :appeal, prefix: true
end
