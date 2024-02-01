# frozen_string_literal: true

class SpecialtyCaseTeamCompletedTasksTab < QueueTab
  validate :assignee_is_organization

  attr_accessor :show_reader_link_column, :allow_bulk_assign

<<<<<<< HEAD
=======
  delegate :column_names, to: :specialty_case_team

>>>>>>> dfe9fd4e30 (Added in the specialty case team queue tabs from APPEALS-35193 to preemptively test how it would intefere with bulk assign. Added the unassigned queue tab and a method to hide it from the queue via in order to give the SCT bulk assign page a tab that it could use as the basis for the page. Added a few more code comments and removed some old unused code.)
  def label
    COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
  end

  def self.tab_name
<<<<<<< HEAD
    Constants.QUEUE_CONFIG.SPECIALTY_CASE_TEAM_COMPLETED_TASKS_TAB_NAME
=======
    Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME
>>>>>>> dfe9fd4e30 (Added in the specialty case team queue tabs from APPEALS-35193 to preemptively test how it would intefere with bulk assign. Added the unassigned queue tab and a method to hide it from the queue via in order to give the SCT bulk assign page a tab that it could use as the basis for the page. Added a few more code comments and removed some old unused code.)
  end

  def description
    COPY::SPECIALTY_CASE_TEAM_QUEUE_PAGE_COMPLETED_TAB_DESCRIPTION
  end

  def tasks
<<<<<<< HEAD
    last_14_days_completed_tasks
=======
    recently_completed_tasks
>>>>>>> dfe9fd4e30 (Added in the specialty case team queue tabs from APPEALS-35193 to preemptively test how it would intefere with bulk assign. Added the unassigned queue tab and a method to hide it from the queue via in order to give the SCT bulk assign page a tab that it could use as the basis for the page. Added a few more code comments and removed some old unused code.)
  end

  def column_names
    SpecialtyCaseTeam::COLUMN_NAMES
  end
end
