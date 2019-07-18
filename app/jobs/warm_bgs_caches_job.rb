# frozen_string_literal: true

class WarmBgsCachesJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def perform
    RequestStore.store[:current_user] = User.system_user
    RequestStore.store[:application] = "hearings"

    warm_participant_caches
    warm_veteran_attribute_caches
  end

  private

  def warm_participant_caches
    RegionalOffice::CITIES.each_key do |ro_id|
      warm_ro_participant_caches([ro_id].flatten) # could be array or string
    end
  end

  def warm_ro_participant_caches(ro_ids)
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

  def warm_veteran_attribute_caches
    # look for hearings for each day up to 6 weeks out and make sure
    # veteran attributes have been cached locally. This optimizes the VETText API.
    # we swallow RecordNotFound errors because some days will legitimately not have
    # hearings scheduled.
    stop_date = (Time.zone.now + 6.weeks).to_date
    date_to_cache = Time.zone.today
    veterans_updated = 0
    while date_to_cache <= stop_date
      begin
        veterans_updated += warm_veterans_for_hearings_on_day(date_to_cache)
        date_to_cache += 1.day
      rescue ActiveRecord::RecordNotFound
        date_to_cache += 1.day
      rescue StandardError => error
        Raven.capture_exception(error)
      end
    end
    notify_slack("Updated cached attributes for #{veterans_updated} Veteran records")
  end

  def warm_veterans_for_hearings_on_day(date_to_cache)
    veterans_updated = 0
    hearings = HearingsForDayQuery.new(day: date_to_cache).call
    hearings.each do |hearing|
      veteran = hearing.appeal.veteran
      if veteran.stale_attributes?
        veteran.update_cached_attributes!
        veterans_updated += 1
      end
    end
    veterans_updated
  end

  def notify_slack(msg)
    slack = SlackService.new(url: ENV["SLACK_DISPATCH_ALERT_URL"])
    slack.send_notification(msg, "WarmBgsCachesJob")
  end
end
