# frozen_string_literal: true

# Executive Management Office inside Education

class EducationEmo < Organization
  def self.singleton
    EducationEmo.first || EducationEmo.create(name: "Executive Management Office", url: "edu-emo")
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
    ]
  end

  def unassigned_tasks_tab
    ::EducationEmoUnassignedTasksTab.new(assignee: self)
  end
end
