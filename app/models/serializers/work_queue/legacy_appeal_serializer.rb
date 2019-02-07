class WorkQueue::LegacyAppealSerializer < ActiveModel::Serializer
  attribute :assigned_attorney
  attribute :assigned_judge
  attribute :sanitized_hearing_request_type

  attribute :issues do
    object.issues.map do |issue|
      ActiveModelSerializers::SerializableResource.new(
        issue,
        serializer: ::WorkQueue::LegacyIssueSerializer
      ).as_json[:data][:attributes]
    end
  end

  attribute :hearings do
    object.hearings.map do |hearing|
      {
        held_by: hearing.judge.present? ? hearing.judge.full_name : "",
        # this assumes only the assigned judge will view the hearing worksheet. otherwise,
        # we should check `hearing.hearing_views.map(&:user_id).include? judge.css_id`
        viewed_by_judge: !hearing.hearing_views.empty?,
        date: hearing.scheduled_for,
        type: hearing.readable_request_type,
        external_id: hearing.external_id,
        disposition: hearing.disposition
      }
    end
  end

  attribute :completed_hearing_on_previous_appeal?

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
  attribute :vbms_id do
    object.sanitized_vbms_id
  end
  attribute :veteran_full_name
  # Aliasing the vbms_id to make it clear what we're returning.
  attribute :veteran_file_number do
    object.sanitized_vbms_id
  end
  attribute :external_id do
    object.vacols_id
  end
  attribute :type
  attribute :aod
  attribute :docket_number
  attribute :status
  attribute :decision_date
  attribute :form9_date
  attribute :nod_date
  attribute :certification_date
  attribute :paper_case do
    object.file_type.eql? "Paper"
  end

  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end

  attribute :veteran_closest_regional_office do
    object.veteran_closest_regional_office
  end

  attribute :veteran_available_hearing_locations do
    locations = object.veteran_available_hearing_locations || []

    locations.map do |ahl|
      {
        name: ahl.name,
        address: ahl.address,
        city: ahl.city,
        state: ahl.state,
        distance: ahl.distance,
        facility_id: ahl.facility_id,
        facility_type: ahl.facility_type,
        classification: ahl.classification,
        zip_code: ahl.zip_code
      }
    end
  end

  attribute :docket_name do
    "legacy"
  end

  attribute :regional_office do
    {
      key: object.regional_office.key,
      city: object.regional_office.city,
      state: object.regional_office.state
    }
  end

  attribute :document_id do
    latest_attorney_case_review&.document_id
  end

  attribute :can_edit_document_id do
    LegacyDocumentIdPolicy.new(
      user: @instance_options[:user],
      case_review: latest_attorney_case_review
    ).editable?
  end

  attribute :attorney_case_review_id do
    latest_attorney_case_review&.vacols_id
  end

  def latest_attorney_case_review
    VACOLS::CaseAssignment.latest_task_for_appeal(object.vacols_id)
  end
end
