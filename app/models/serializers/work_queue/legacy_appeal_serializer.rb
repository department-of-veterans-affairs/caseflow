class WorkQueue::LegacyAppealSerializer < ActiveModel::Serializer
  attribute :issues do
    object.issues.map do |issue|
      ActiveModelSerializers::SerializableResource.new(
        issue,
        serializer: ::WorkQueue::IssueSerializer
      ).as_json[:data][:attributes]
    end
  end

  attribute :hearings do
    object.hearings.map do |hearing|
      {
        held_by: hearing.user.present? ? hearing.user.full_name : "",
        # this assumes only the assigned judge will view the hearing worksheet. otherwise,
        # we should check `hearing.hearing_views.map(&:user_id).include? judge.css_id`
        viewed_by_judge: !hearing.hearing_views.empty?,
        date: hearing.date,
        type: hearing.type,
        id: hearing.id,
        disposition: hearing.disposition
      }
    end
  end

  attribute :appellant_full_name do
    object.appellant_name
  end

  attribute :appellant_address do
    {
      address_line_1: object.appellant_address_line_1,
      address_line_2: object.appellant_address_line_2,
      city: object.appellant_city,
      state: object.appellant_state,
      zip: object.appellant_zip,
      country: object.appellant_country
    }
  end

  attribute :appellant_relationship
  attribute :location_code
  attribute :veteran_full_name
  attribute :veteran_date_of_birth
  attribute :veteran_gender
  attribute :vbms_id do
    object.sanitized_vbms_id
  end
  attribute :vacols_id
  attribute :type
  attribute :aod
  attribute :docket_number
  attribute :status
  attribute :decision_date
  attribute :certification_date
  attribute :paper_case do
    object.file_type.eql? "Paper"
  end

  attribute :power_of_attorney do
    {
      representative_type: object.representative_type,
      representative_name: object.representative_name
    }
  end

  attribute :regional_office do
    {
      key: object.regional_office.key,
      city: object.regional_office.city,
      state: object.regional_office.state
    }
  end
  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end
end
