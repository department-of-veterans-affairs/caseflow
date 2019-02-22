class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :issues do
    object.eligible_request_issues.map do |issue|
      {
        id: issue.id,
        disposition: issue.disposition,
        program: issue.benefit_type,
        description: issue.description,
        notes: issue.notes,
        diagnostic_code: issue.contested_rating_issue_diagnostic_code,
        remand_reasons: issue.remand_reasons
      }
    end
  end

  attribute :decision_issues do
    object.decision_issues.uniq.map do |issue|
      {
        id: issue.id,
        disposition: issue.disposition,
        description: issue.description,
        benefit_type: issue.benefit_type,
        remand_reasons: issue.remand_reasons,
        diagnostic_code: issue.diagnostic_code,
        request_issue_ids: issue.request_decision_issues.pluck(:request_issue_id)
      }
    end
  end

  attribute :can_edit_request_issues do
    @instance_options[:user]&.can_edit_request_issues?(object)
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

  attribute :location_code do
    object.location_code
  end

  attribute :completed_hearing_on_previous_appeal? do
    false
  end

  attribute :appellant_full_name do
    object.claimants[0].name if object.claimants&.any?
  end

  attribute :appellant_address do
    if object.claimants&.any?
      object.claimants[0].address
    end
  end

  attribute :appellant_relationship do
    object.claimants[0].relationship if object.claimants&.any?
  end

  attribute :veteran_file_number do
    object.veteran_file_number
  end

  attribute :veteran_full_name do
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
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

  attribute :external_id do
    object.uuid
  end

  attribute :type do
    "Original"
  end

  attribute :aod do
    object.advanced_on_docket
  end

  attribute :docket_name do
    object.docket_name
  end

  attribute :docket_number do
    object.docket_number
  end

  attribute :decision_date do
    object.decision_date
  end

  attribute :nod_date do
    object.receipt_date
  end

  attribute :certification_date do
    nil
  end

  attribute :paper_case do
    false
  end

  attribute :regional_office do
  end

  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end

  attribute :document_id do
    latest_attorney_case_review&.document_id
  end

  attribute :attorney_case_review_id do
    latest_attorney_case_review&.id
  end

  attribute :attorney_case_rewrite_details do
    {
      overtime: latest_attorney_case_review&.overtime,
      note_from_attorney: latest_attorney_case_review&.note,
      untimely_evidence: latest_attorney_case_review&.untimely_evidence
    }
  end

  attribute :can_edit_document_id do
    AmaDocumentIdPolicy.new(
      user: @instance_options[:user],
      case_review: latest_attorney_case_review
    ).editable?
  end
  def latest_attorney_case_review
    @latest_attorney_case_review ||=
      AttorneyCaseReview.where(task_id: Task.where(appeal: object).pluck(:id)).order(:created_at).last
  end
end
