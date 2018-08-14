class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :veteran_gender
  attribute :veteran_is_deceased do
    !!object.notice_of_death_date
  end

  attribute :appellant_is_not_veteran do
    !!object.appellant_first_name
  end
  attribute :appellant_first_name
  attribute :appellant_middle_name do
    object.appellant_middle_initial
  end
  attribute :appellant_last_name
  attribute :appellant_name_suffix
  attribute :file_number do
    object.sanitized_vbms_id
  end
  attribute :citation_number
  attribute :docket_number
  attribute :number_of_issues do
    object.issues.length
  end
  attribute :issues do
    object.issues.map do |issue|
      ActiveModelSerializers::SerializableResource.new(
        issue,
        serializer: ::WorkQueue::IssueSerializer
      ).as_json[:data][:attributes]
    end
  end

  # TODO: - expand rep name into separate fields
  attribute :representative_name do
    object.power_of_attorney.vacols_representative_name
  end
  attribute :representative_type do
    object.power_of_attorney.vacols_representative_type
  end

  attribute :aod
  attribute :cavc
  attribute :status

  attribute :previously_selected_for_quality_review do
    # TODO: — if this endpoint is slow, make this a join
    object.previously_selected_for_quality_review
  end

  attribute :documents do
    tasks.map do |task|
      {
        added_by_first_name: task.added_by_first_name, 
        added_by_middle_name: task.added_by_middle_name, 
        added_by_last_name: task.added_by_last_name,
        written_by_first_name: task.attorney_first_name,
        written_by_middle_name: task.attorney_middle_name,
        written_by_last_name: task.attorney_last_name,
        document_id: task.document_id
      }
    end
  end

  attribute :has_outstanding_mail do
    object.has_outstanding_vacols_mail?
  end
end
