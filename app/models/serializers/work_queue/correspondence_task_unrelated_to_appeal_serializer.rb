# frozen_string_literal: true

class WorkQueue::CorrespondenceTaskUnrelatedToAppealSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attributes :label, :status, :instructions

  attribute :assigned_on do |task|
    task.assigned_at.strftime("%m/%d/%Y")
  end

  attribute :assigned_to do |task|
    (task.assigned_to_type == "Organization") ? task.assigned_to.name : task.assigned_to.css_id
  end

  attribute :type, &:assigned_to_type

  attribute :unique_id, &:id

  attribute :available_actions do |task|
    task.available_actions_unwrapper(RequestStore[:current_user])
  end

  attribute :assigned_by, if: proc { |task| task.is_a?(ReturnToInboundOpsTask) } do |task|
    task.assigned_by.css_id
  end

  attribute :reassign_users, if: proc { |task| task.open? }, &:reassign_users

  attribute :assigned_to_org, if: proc { |task| task.open? } do |task|
    task.assigned_to.is_a?(Organization)
  end

  attribute :organizations, if: proc { |task| task.open? } do |task|
    task.reassign_organizations.map { |org| { label: org.name, value: org.id } }
  end
end
