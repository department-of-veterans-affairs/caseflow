# frozen_string_literal: true

##
# Basically the TaskPager, but has a required filter by regional key.

class Hearings::ScheduleHearingTaskPager < TaskPager
  attr_accessor :regional_office_key

  def initialize(args)
    super(args)
  end

  def tasks_for_tab
    tab = QueueTab.from_name(tab_name).new(
      assignee: assignee,
      regional_office_key: regional_office_key
    )

    @tasks_for_tab ||= tab.tasks
  end
end
