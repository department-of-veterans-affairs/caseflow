# frozen_string_literal: true

class TaskBulkCreator
  include ActiveModel::Model

  def initialize(params)
    @params = params
  end

  def create
    @success = tasks.all?(&:valid?)

    FormResponse.new(success: success, errors: [response_errors], extra: tasks)
  end

  private

  attr_reader :params, :success

  def parents
    @parents ||= Task.where(id: params[:parent_ids])
      .order(:created_at)
      .limit(params[:number_of_tasks])
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: params[:assigned_to_id])
  end

  def tasks
    if parents.count != params[:number_of_tasks]
      errors.add(:parent_ids, "are invalid")
      return
    end
    parents.map do |parent|
      Task.create(
        type: parent.type,
        parent: parent,
        appeal: parent.appeal,
        assigned_to: assigned_to,
        assigned_by: params[:assigned_by]
      )
    end
  end

  def response_errors
    return if success

    {
      title: "Record is invalid",
      detail: errors.full_messages.join(", ")
    }
  end
end
