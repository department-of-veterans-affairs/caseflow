# frozen_string_literal: true

class WorkQueue::AppealSerializerSearch
  include FastJsonapi::ObjectSerializer
  extend Helpers::AppealHearingHelper

  set_type :appeal

  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :appellant_hearing_email_recipient do |object|
    object.email_recipients.find_by(type: "AppellantHearingEmailRecipient")
  end
  attribute :representative_hearing_email_recipient do |object|
    object.email_recipients.find_by(type: "RepresentativeHearingEmailRecipient")
  end

  attribute :appellant_email_address do |object|
    object.appellant ? object.appellant.email_address : "Cannot Find Appellant"
  end

  attribute :current_user_email do |_, params|
    params[:user]&.email
  end

  attribute :current_user_timezone do |_, params|
    params[:user]&.timezone
  end

  attribute :contested_claim, &:contested_claim?

  attribute :issues do |object|
    object.request_issues.active_or_decided_or_withdrawn.includes(:remand_reasons).map do |issue|
      {
        id: issue.id,
        program: issue.benefit_type,
        description: issue.description,
        notes: issue.notes,
        diagnostic_code: issue.contested_rating_issue_diagnostic_code,
        remand_reasons: issue.remand_reasons,
        closed_status: issue.closed_status,
        decision_date: issue.decision_date
      }
    end
  end

  attribute :status

  attribute(:hearings) do |object, params|
    # For substitution appeals after death dismissal, we need to show hearings from the source appeal
    # in addition to those on the new/target appeal; this avoids copying them to new appeal stream
    associated_hearings = []

    if object.separate_appeal_substitution?
      associated_hearings = hearings(object.appellant_substitution.source_appeal, params)
    end

    associated_hearings + hearings(object, params)
  end

  attribute :withdrawn, &:withdrawn?

  attribute :removed, &:removed?

  attribute :overtime, &:overtime?

  attribute :veteran_appellant_deceased, &:veteran_appellant_deceased?

  attribute :assigned_to_location

  attribute :distributed_to_a_judge, &:distributed_to_a_judge?

  attribute :appellant_is_not_veteran

  attribute :appellant_full_name do |object|
    object.claimant&.name
  end

  attribute :appellant_relationship, &:appellant_relationship

  attribute :has_poa do |appeal|
    appeal.claimant&.power_of_attorney
  end

  attribute :cavc_remand do |object|
    if object.cavc_remand
      WorkQueue::CavcRemandSerializer.new(object.cavc_remand).serializable_hash[:data][:attributes]
    end
  end

  attribute :show_post_cavc_stream_msg do |object|
    cavc_remand = CavcRemand.find_by(source_appeal_id: object.id)
    cavc_remand.present? && cavc_remand.cavc_remands_appellant_substitution.present?
  end

  attribute :veteran_death_date

  attribute :veteran_file_number

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :external_id, &:uuid

  attribute :type
  attribute :vacate_type
  attribute :aod, &:advanced_on_docket?
  attribute :docket_name
  attribute :docket_number
  attribute :docket_range_date
  attribute :decision_date
  attribute :nod_date, &:receipt_date
  attribute :withdrawal_date

  attribute :caseflow_veteran_id do |object|
    object.veteran ? object.veteran.id : nil
  end

  attribute :document_id do |object|
    object.latest_attorney_case_review&.document_id
  end

  attribute :attorney_case_review_id do |object|
    object.latest_attorney_case_review&.id
  end

  attribute :docket_switch do |object|
    if object.docket_switch
      WorkQueue::DocketSwitchSerializer.new(object.docket_switch).serializable_hash[:data][:attributes]
    end
  end
end
