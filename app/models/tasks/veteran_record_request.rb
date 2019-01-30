class VeteranRecordRequest < GenericTask
  include BusinessLineTask

  def label
    "Record Request"
  end

  def serializer_class
    ::WorkQueue::VeteranRecordRequestSerializer
  end
end
