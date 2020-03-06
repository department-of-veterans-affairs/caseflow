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
    warm_poa_caches
    datadog_report_runtime(metric_group_name: "warm_bgs_caches_job")
  end

  private

  def warm_poa_caches
    # we average about 10k Claimant rows created a week.
    # we very rarely update the Claimant record after we create it.
    # so we can use the Claimant.updated_at to reflect how recently we've
    # warmed our local POA cache.
    # we keep our daily batch modestly sized to avoid taxing BGS
    # but large enough to satisfy UpdateCachedAppealsAttributesJob
    # which relies on our local POA cache.
    # we only care about Appeal Claimants because that's all
    # UpdateCachedAppealsAttributesJob cares about.
    # assuming we have 40k open appeals/claimants at any given time,
    # and we cache each one for 30 days, we want to cache about 1400 a day.
    start_time = Time.zone.now
    oldest_claimants_for_open_appeals.limit(1400).each do |claimant|
      claimant.representative_name # updates_cache
      claimant.update!(updated_at: Time.zone.now)
    end
    datadog_report_time_segment(segment: "warm_poa_caches", start_time: start_time)
  end

  def claimants_for_open_appeals
    Claimant.where(decision_review_type: Appeal.name, decision_review_id: open_appeals_from_tasks)
  end

  def oldest_claimants_for_open_appeals
    claimants_for_open_appeals.order(updated_at: :asc)
  end

  def open_appeals_from_tasks
    Task.open.where(appeal_type: Appeal.name).pluck(:appeal_id).uniq
  end

  def warm_people_caches
    Person.where(first_name: nil, last_name: nil)
      .order(created_at: :desc)
      .limit(12_000)
      .each(&:update_cached_attributes!)
  rescue StandardError => error
    Raven.capture_exception(error)
  end

  def warm_participant_caches
    start_time = Time.zone.now
    RegionalOffice::CITIES.each_key do |ro_id|
      warm_ro_participant_caches([ro_id].flatten) # could be array or string
    rescue StandardError => error
      Raven.capture_exception(error)
    end
    datadog_report_time_segment(segment: "warm_participant_caches", start_time: start_time)
  end

  def warm_ro_participant_caches(ro_ids)
    start_time = Time.zone.now
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
    datadog_report_time_segment(segment: "warm_ro_participant_caches", start_time: start_time)
  end

  def warm_veteran_attribute_caches
    # look for hearings for each day up to 3 weeks out and make sure
    # veteran attributes have been cached locally. This optimizes the VETText API.
    # we swallow RecordNotFound errors because some days will legitimately not have
    # hearings scheduled.
    stop_date = (Time.zone.now + 2.weeks).to_date
    date_to_cache = Time.zone.today
    veterans_updated = 0
    start_time = Time.zone.now
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
    datadog_report_time_segment(segment: "warm_veteran_attribute_caches", start_time: start_time)
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
end
