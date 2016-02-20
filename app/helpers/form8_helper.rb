module Form8Helper
  def record_type_check_boxes
    Form8::RECORD_TYPE_FIELDS.map do |record_type|
      { attribute: record_type[:attribute], label: record_type[:name] }
    end
  end
end
