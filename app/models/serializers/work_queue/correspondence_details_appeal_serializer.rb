# frozen_string_literal: true

class WorkQueue::CorrespondenceDetailsAppealSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :id
  # attribute :correspondences_appeals_tasks
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

  attribute :appeal do |object|
    WorkQueue::AppealSerializer.new(object, params: { user: RequestStore[:current_user] })
  end

  attribute :task_added_data do |object|
    # include waivable evidence window tasks
    evidence_window_task = object.tasks.find_by(type: EvidenceSubmissionWindowTask.name)

    tasks = object.tasks.uniq
    tasks << evidence_window_task if evidence_window_task&.waivable?
    AmaAndLegacyTaskSerializer.create_and_preload_legacy_appeals(
      params: { user: RequestStore[:current_user], role: "generic" },
      tasks: tasks,
      ama_serializer: WorkQueue::TaskSerializer
    ).call
  end

  # count values pulled from WorkQueue::AppealSerializer issue attribute
  attribute :issue_count do |object|
    object.request_issues.active_or_decided_or_withdrawn.includes(:remand_reasons).count
  end

  attribute :assigned_to do |object|
    object.tasks[0]&.assigned_to
  end

  attribute :assigned_to_location do |object, params|
    if object&.status&.status == :distributed_to_judge
      if params[:user]&.judge? || params[:user]&.attorney? || User.list_hearing_coordinators.include?(params[:user])
        object.assigned_to_location
      end
    else
      object.assigned_to_location
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
