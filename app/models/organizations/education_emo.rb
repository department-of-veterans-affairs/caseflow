# frozen_string_literal: true

# Executive Management Office inside Education

class EducationEmo < Organization
  def self.singleton
    EducationEmo.first || EducationEmo.create(name: "Executive Management Office", url: "edu-emo")
  end

  def queue_tabs
    [
      assigned_tasks_tab
    ]
  end

  def assigned_tasks_tab
    ::EducationAssignedTasksTab.new(assignee: self)
  end
end
