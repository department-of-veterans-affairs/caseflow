class Idt::V1::AppealSerializer < ActiveModel::Serializer
  # :nocov
  # TODO: serialize AMA appeals with this serializer
  def id
    object.vacols_id
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :file_number do
    object.sanitized_vbms_id
  end
  attribute :docket_number
  attribute :number_of_issues do
    object.issues.length
  end
  # :nocov
end
