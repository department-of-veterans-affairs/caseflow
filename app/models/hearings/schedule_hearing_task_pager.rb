# frozen_string_literal: true

##
# Basically the TaskPager, but has a required filter by regional key.

class Hearings::ScheduleHearingTaskPager < TaskPager
  attr_accessor :regional_office_key

  def initialize(args)
    super(args)
  end

  def tasks_for_tab
    tab = AssignHearing.new(
      appeal_type: appeal_type,
      regional_office_key: regional_office_key
    )

    @tasks_for_tab ||= tab.tasks
  end

  def tasks_for_tab_count
    @tasks_for_tab_count ||= tasks_for_tab.count
  end

  # Sorting by docket number within each category of appeal: AOD and normal.
  def sorted_tasks(tasks)
    tasks.order(Arel.sql(<<-SQL))
      (CASE
        WHEN cached_appeal_attributes.case_type = 'Court Remand' THEN 1
        ELSE 0
      END) DESC,
      cached_appeal_attributes.is_aod DESC,
      cached_appeal_attributes.docket_number ASC
    SQL
  end

  def appeal_type
    if tab_name == Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME
      Appeal.name
    elsif tab_name == Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME
      LegacyAppeal.name
    else
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: tab_name,
        message: "Tab does not exist"
      )
    end
  end
end
