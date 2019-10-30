# frozen_string_literal: true

class WarmBgsCachesJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    RequestStore.store[:current_user] = User.system_user
    RequestStore.store[:application] = "hearings"

    warm_participant_caches
    warm_veteran_attribute_caches
    warm_people_caches
  end

  private

  def warm_people_caches
    Person.where(first_name: nil, last_name: nil)
      .order(created_at: :desc)
      .limit(12_000)
      .each(&:update_cached_attributes!)
  rescue StandardError => error
    Raven.capture_exception(error)
  end

  def warm_participant_caches
    RegionalOffice::CITIES.each_key do |ro_id|
      warm_ro_participant_caches([ro_id].flatten) # could be array or string
    rescue StandardError => error
      Raven.capture_exception(error)
    end
  end

  def warm_ro_participant_caches(ro_ids)
    ro_ids.each do |ro_id|
      regional_office = HearingDayMapper.validate_regional_office(ro_id)

      HearingDayRange.new(
        Time.zone.today.beginning_of_day,
        Time.zone.today.beginning_of_day + 182.days,
        regional_office
      ).open_hearing_days_with_hearings_hash(RequestStore.store[:current_user].id)
    rescue StandardError => error
      # Ensure errors are sent to Sentry, but don't block the job from continuing.
      Raven.capture_exception(error)
    end
  end

  def warm_veteran_file_number_caches(limit)
    # look for Veteran records where we only have a 9 digit file_number
    # and look for a *real* 8 digit file number.
    bgs = BGSService.new
    vets_with_one_record_looks_like_ssn = Veteran
      .where("char_length(file_number) = 9")
      .where(participant_id: Veteran.group(:participant_id).having("count(*) = 1").select(:participant_id))
      .order(id: :asc)
    vets_with_one_record_looks_like_ssn.limit(limit).each do |veteran|
      cache_key = "bgs-pid-lookup-#{veteran.participant_id}"
      file_number = Rails.cache.fetch(cache_key, expires_in: 90.days) do
        bgs_vet = bgs.client.veteran.find_by_participant_id veteran.participant_id
        return unless bgs_vet

        bgs_vet[:file_number]
      end
      next unless file_number && file_number != veteran.file_number

      Veteran.find_or_create_by_file_number(file_number, sync_name: true)
    end
  end

  def warm_veteran_attribute_caches
    # look for hearings for each day up to 3 weeks out and make sure
    # veteran attributes have been cached locally. This optimizes the VETText API.
    # we swallow RecordNotFound errors because some days will legitimately not have
    # hearings scheduled.
    stop_date = (Time.zone.now + 2.weeks).to_date
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

      if veteran&.stale_attributes?
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
