# frozen_string_literal: true

class AssignHearing
  attr_accessor :regional_office_key, :appeal_type

  def initialize(appeal_type:, regional_office_key:)
    @appeal_type = appeal_type
    @regional_office_key = regional_office_key
  end

  def tasks
    ScheduleHearingTask
      .includes(*task_includes)
      .active
      .where(appeal_type: appeal_type)
      .joins(CachedAppeal.left_join_from_tasks_clause)
      .where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)
  end

  def to_hash
    { columns: columns }
  end

  def columns
    [
      {
        name: "powerOfAttorney",
        filter_options: power_of_attorney_name_options(tasks)
      },
      {
        name: "suggestedLocation",
        filter_options: suggested_location_options(tasks)
      }
    ]
  end

  # TODO: Implement, must cache powerOfAttorney
  def power_of_attorney_name_options(tasks)
    [{ value: "Power of Attorney", displayText: "Power of Attorney" }]
  end

  # TODO: Implement, maybe cache suggestedLocation
  def suggested_location_options(tasks)
    [{ value: "Suggested Location", displayText: "Suggested Location" }]
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      { attorney_case_reviews: [:attorney] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end
end
