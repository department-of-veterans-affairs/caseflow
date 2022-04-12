# frozen_string_literal: true

# Executive Management Office inside Education

class EducationEmo < Organization
  def self.singleton
    EducationEmo.first || EducationEmo.create(name: "Executive Management Office", url: "edu-emo")
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
      completed_tasks_tab#,
      #assigned_tasks_tab,
      #completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    ::EducationEmoUnassignedTasksTab.new(assignee: self)
  end

  def completed_tasks_tab
    ::VhaProgramOfficeCompletedTasksTab.new(assignee: self)
  end

  # def assigned_tasks_tab
  #   ::EducationAssignedTasksTab.new(assignee: self)
  # end

  # def completed_tasks_tab
  #   ::EducationCompletedTasksTab.new(assignee: self)
  # end
end
