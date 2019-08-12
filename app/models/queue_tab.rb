# frozen_string_literal: true

class QueueTab
  include ActiveModel::Model

  attr_accessor :assignee, :show_regional_office_column

  def self.from_name(tab_name)
    tab = subclasses.find { |subclass| subclass.tab_name == tab_name }
    fail(Caseflow::Error::InvalidTaskTableTab, tab_name: tab_name) unless tab

    tab
  end

  def to_hash
    {
      label: label,
      name: name,
      description: format(description, assignee.name),
      columns: columns,
      allow_bulk_assign: allow_bulk_assign?
    }
  end

  def label; end

  def self.tab_name; end

  def tasks; end

  def description; end

  def columns; end

  def name
    self.class.tab_name
  end

  def allow_bulk_assign?
    false
  end

  private

  def on_hold_tasks
    Task.includes(*task_includes).visible_in_queue_table_view.where(assigned_to: assignee).on_hold
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

require_dependency "assigned_tasks_tab"
require_dependency "completed_tasks_tab"
require_dependency "on_hold_tasks_tab"
require_dependency "tracking_tasks_tab"
require_dependency "unassigned_tasks_tab"
