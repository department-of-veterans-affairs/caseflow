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

  # Returns all results after the current page (unfiltered) in sorted order.
  def tasks_after_current_page
    tasks_for_tab.offset(page * TASKS_PER_PAGE)
  end

  # Get count of records where AOD = true OR docket range date is before end date 
  # AFTER the current page
  #
  # If there are records after the current page, set "docket_line_index" to null
  #
  # If there aren't records after the current page, traverse the list of tasks, and figure
  # out where the last record with a docket_range_date is, and have that be the index for 
  # "docket_line_index"
  def docket_line_index(current_page)
    case appeal_type
    when Appeal.name
      appeals_past_docket_line_count = tasks_after_current_page
        .joins(Arel.sql(<<-SQL))
          LEFT JOIN appeals
          ON tasks.appeal_id = appeals.id
          AND tasks.appeal_type = 'Appeal'
        SQL
        .where(Arel.sql(<<-SQL), current_date: Time.zone.today)
          cached_appeal_attributes.is_aod OR
          appeals.docket_range_date < :current_date
        SQL
        .count

      return nil if appeals_past_docket_line_count > 0

      docket_range_cutoff = (Time.zone.today + 1.month).end_of_month
      idx = current_page.size - 1
      current_page.reverse_each do |task|
        if task&.appeal&.docket_range_date &.< docket_range_cutoff
          break
        else
          idx -= 1
        end
      end

      idx < 0 ? nil : idx
    else
      nil
    end
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
end
