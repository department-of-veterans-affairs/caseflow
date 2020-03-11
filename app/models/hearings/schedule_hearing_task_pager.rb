# frozen_string_literal: true

##
# Basically the TaskPager, but has a required filter by regional key.

class Hearings::ScheduleHearingTaskPager < TaskPager
  attr_accessor :regional_office_key

  def initialize(args)
    super(args)
  end

  def tasks_for_tab
    tab = AssignHearingTab.new(
      appeal_type: appeal_type,
      regional_office_key: regional_office_key
    )

    @tasks_for_tab ||= tab.tasks
  end

  # the index of the docket line, which is drawn below the set of tasks
  # that are attached to appeals that are within docket range or have
  # AOD status
  def docket_line_index
    return nil unless maybe_show_docket_line?

    # step through tasks from the bottom up to determine if we should
    # show a docket line on the current page
    task_index = paged_tasks.size - 1
    paged_tasks.reverse_each do |task|
      break if !!(task.appeal&.docket_range_date &.< docket_line_cutoff_date) || task.appeal&.aod?

      task_index -= 1
    end

    (task_index < 0) ? nil : task_index
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
    case tab_name
    when Constants.QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME
      Appeal.name
    when Constants.QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME
      LegacyAppeal.name
    else
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: tab_name,
        message: "Tab does not exist"
      )
    end
  end

  private

  # return true if we may want to show the docket line on the current page
  def maybe_show_docket_line?
    # no line for non-AMA appeals
    return false if appeal_type != Appeal.name

    # no line if filters are applied
    return false if filters.any?

    # no line if there are no tasks in tabs after the current one with a
    # docket range date before a cutoff date or AOD status
    return false if number_of_docket_line_tasks_after_current_page > 0

    # we may want to show a docket line
    true
  end

  # all (unfiltered) tasks after the current page
  def tasks_after_current_page
    tasks_for_tab.offset(page * TASKS_PER_PAGE)
  end

  def docket_line_cutoff_date
    (Time.zone.today + 1.month).end_of_month
  end

  def number_of_docket_line_tasks_after_current_page
    tasks_after_current_page
      .joins(Arel.sql(<<-SQL))
        LEFT JOIN appeals
        ON tasks.appeal_id = appeals.id
        AND tasks.appeal_type = 'Appeal'
      SQL
      .where(Arel.sql(<<-SQL), cutoff_date: docket_line_cutoff_date)
        cached_appeal_attributes.is_aod OR
        appeals.docket_range_date < :cutoff_date
      SQL
      .count
  end
end
