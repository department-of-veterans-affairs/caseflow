# frozen_string_literal: true

class WarmBgsParticipantCachesJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def perform
    RequestStore.store[:current_user] = User.system_user
    RequestStore.store[:application] = "hearings"

    RegionalOffice::CITIES.each_key do |ro_id|
      process([ro_id].flatten) # could be array or string
    end
  end

  def process(ro_ids)
    ro_ids.each do |ro_id|
      regional_office = HearingDayMapper.validate_regional_office(ro_id)

      HearingDay.open_hearing_days_with_hearings_hash(
        Time.zone.today.beginning_of_day,
        Time.zone.today.beginning_of_day + 182.days,
        regional_office,
        RequestStore.store[:current_user].id
      )
    rescue StandardError => error
      # Ensure errors are sent to Sentry, but don't block the job from continuing.
      Raven.capture_exception(error)
    end
  end
end
