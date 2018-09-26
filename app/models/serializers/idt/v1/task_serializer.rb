class Idt::V1::TaskSerializer < ActiveModel::Serializer
  def id
    appeal.is_a?(LegacyAppeal) ? appeal.vacols_id : appeal.uuid
  end

  def appeal
    object.appeal
  end

  attribute :appeal_type 
  attribute :days_waiting

  attribute :veteran_first_name do
    appeal.veteran_first_name
  end
  attribute :veteran_middle_name do
    appeal.veteran_middle_initial
  end
  attribute :veteran_last_name do
    appeal.veteran_last_name
  end
  attribute :file_number do
    appeal.is_a?(LegacyAppeal) ? appeal.sanitized_vbms_id : appeal.veteran_file_number
  end
  attribute :docket_number do
    appeal.docket_number
  end
  attribute :docket_name do
    appeal.docket_name
  end
  attribute :number_of_issues do
    appeal.number_of_issues
  end

  attribute :assigned_by_name

  attribute :documents do
    object.attorney_case_reviews.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
  end
end
