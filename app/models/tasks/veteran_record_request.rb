class VeteranRecordRequest < GenericTask
  def label
    "Record Request"
  end

  def serializer_class
    ::WorkQueue::VeteranRecordRequestSerializer
  end

  def ui_hash
    serializer_class.new(self).as_json
  end
end
