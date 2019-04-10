# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO: should only return genpop appeals.
  # rubocop:disable Lint/UnusedMethodArgument
  def age_of_n_oldest_priority_appeals(num)
    []
  end

  # CMGTODO
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1)
    []
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def appeals_in_docket_range
    target = DocketCoordinator.new.target_number_of_ama_hearings_this_month
    target = 30 if target == 0 # for testing

    appeals_in_range = appeals(priority: false)
    held_hearings = Hearing.where(appeal: appeals_in_range, disposition: "held").where.not(
      hearing_day: HearingDay.where(scheduled_for: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)
    )

    appeals_in_range.where.not(id: held_hearings.pluck(:appeal_id)).limit(target)
  end

  def appeals_in_docket_range_for_regional_office(regional_office)
    appeals_in_docket_range.select { |appeal| appeal.closest_regional_office == regional_office }
  end
end
