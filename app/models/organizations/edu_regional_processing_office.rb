# frozen_string_literal: true

class EduRegionalProcessingOffice < Organization
  def can_receive_task?(_task)
    false
  end

  def queue_tabs
    [
      in_progress_tab
    ]
  end

  def in_progress_tab
    ::EducationRpoInProgressTasksTab.new(assignee: self)
  end
end
