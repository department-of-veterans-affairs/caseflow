# frozen_string_literal: true

class SpecialtyCaseTeamUnassignedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

  def label
<<<<<<< HEAD
    COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE
  end

  def self.tab_name
    Constants.QUEUE_CONFIG.SPECIALTY_CASE_TEAM_UNASSIGNED_TASKS_TAB_NAME
  end

  def description
    format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, assignee.name)
  end

  def tasks
    assigned_tasks
=======
    "COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE"
  end

  def self.tab_name
    "unassignedTab"
  end

  def description
    "COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_COMPLETED_TAB_DESCRIPTION"
  end

  def tasks
    active_tasks
>>>>>>> dfe9fd4e30 (Added in the specialty case team queue tabs from APPEALS-35193 to preemptively test how it would intefere with bulk assign. Added the unassigned queue tab and a method to hide it from the queue via in order to give the SCT bulk assign page a tab that it could use as the basis for the page. Added a few more code comments and removed some old unused code.)
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end

<<<<<<< HEAD
  # This only affects bulk assign on the standard queue tab view
  def allow_bulk_assign?
    true
  end
=======
  # TODO: This only affects bulk assign on the standard queue tab view
  # def allow_bulk_assign?
  #   true
  # end
>>>>>>> dfe9fd4e30 (Added in the specialty case team queue tabs from APPEALS-35193 to preemptively test how it would intefere with bulk assign. Added the unassigned queue tab and a method to hide it from the queue via in order to give the SCT bulk assign page a tab that it could use as the basis for the page. Added a few more code comments and removed some old unused code.)

  def hide_from_queue_table_view
    true
  end
end
