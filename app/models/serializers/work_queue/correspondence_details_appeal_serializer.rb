# frozen_string_literal: true

class WorkQueue::CorrespondenceDetailsAppealSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :id
  attribute :external_id, &:uuid
  attribute :docket_name
  attribute :decision_date
  attribute :overtime, &:overtime?
  attribute :withdrawn, &:withdrawn?
  attribute :case_type, &:type
  attribute :aod, &:advanced_on_docket?
  attribute :docket_number, &:docket_number
  attribute :veteran_name, &:veteran
  attribute :stream_type, &:stream_type
  attribute :appeal_type, &:docket_type
  attribute :status, &:status

  attribute :appellant_full_name do |object|
    object.claimant&.name
  end

  attribute :veteran_full_name do |object|
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :number_of_issues do |object|
    object.issues.length
  end

  # count values pulled from WorkQueue::AppealSerializer issue attribute
  attribute :issue_count do |object|
    object.request_issues.active_or_decided_or_withdrawn.includes(:remand_reasons).count
  end

  attribute :assigned_to do |object|
    object.tasks[0]&.assigned_to
  end

  attribute :assigned_to_location do |obj, params|
    if obj&.status&.status == :distributed_to_judge
      if params[:user]&.judge? || params[:user]&.attorney? || User.list_hearing_coordinators.include?(params[:user])
        obj.assigned_to_location
      end
    else
      obj.assigned_to_location
    end
  end

  attribute :correspondence do |object|
    object
  end

  # badges attributes
  attribute :veteran_appellant_deceased, &:veteran_appellant_deceased?
  attribute :contested_claim, &:contested_claim?
  attribute :mst, &:mst?
  attribute :pact, &:pact?
end
