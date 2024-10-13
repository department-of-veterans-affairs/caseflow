# frozen_string_literal: true

class GenericQueue
  def initialize(limit: 10_000, user:)
    @limit = limit
    @user = user
  end

  def tasks
    relevant_tasks
  end

  private

  attr_reader :limit, :user

  def relevant_tasks
    Task.incomplete_or_recently_completed.visible_in_queue_table_view
      .where(assigned_to: user)
      .not_correspondence
      .includes(*task_includes)
      .order(created_at: :asc)
      .limit(limit)
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end
end
