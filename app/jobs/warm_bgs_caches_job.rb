# frozen_string_literal: true

class WarmBgsCachesJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    RequestStore.store[:current_user] = User.system_user
    RequestStore.store[:application] = "hearings"

    warm_poa_caches # run first since other warmers benefit from it being updated.
    warm_participant_caches
    warm_veteran_attribute_caches
    warm_people_caches
    warm_attorney_address_caches

    datadog_report_runtime(metric_group_name: "warm_bgs_caches_job")
  end

  private

  def warning_msgs
    @warning_msgs ||= []
  end

  CACHED_APPEALS_BGS_POA_COLUMNS = [
    :power_of_attorney_name
  ].freeze

  def warm_poa_caches
    # We do 2 passes to update our POA cache (bgs_power_of_attorney table).
    # 1. Look at the 1000 oldest cached records and update them.
    # 2. Look at Claimants w/o POA associated record and create cached record.

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
    # we want to check about 1400 a day to cycle through them all once a month.
    warm_poa_and_cache_for_legacy_appeals_with_hearings
    warm_poa_and_cache_for_ama_appeals_with_hearings
    warm_poa_and_cache_ama_appeals_for_oldest_claimants
    warm_poa_for_oldest_cached_records

    log_warning unless warning_msgs.empty?
  end

  def warm_poa_and_cache_for_legacy_appeals_with_hearings
    start_time = Time.zone.now

    appeals_to_cache = legacy_appeal_ids_to_file_numbers(1000).map do |appeal_id, file_number|
      bgs_poa = fetch_bgs_power_of_attorney_by_file_number(file_number, appeal_id)

      # [{:appeal_id=>1, :appeal_type=>"LegacyAppeal", :power_of_attorney_name=>"Clarence Darrow"}, ...]
      warm_bgs_poa_and_return_cache_data(bgs_poa, appeal_id, LegacyAppeal.name)
    end.compact

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {
      conflict_target: [:appeal_id, :appeal_type], columns: CACHED_APPEALS_BGS_POA_COLUMNS
    }

    datadog_report_time_segment(segment: "warm_poa_bgs_and_cache_legacy", start_time: start_time)
  end

  def warm_poa_and_cache_for_ama_appeals_with_hearings
    start_time = Time.zone.now

    # only process the first 1000 appeals
    appeal_ids = appeal_ids_with_hearings.first(1000)
    claimants_for_hearing = Claimant.where(decision_review_type: Appeal.name, decision_review_id: appeal_ids)

    appeals_to_cache = claimants_for_hearing.map do |claimant|
      bgs_poa = claimant.power_of_attorney
      claimant.update!(updated_at: Time.zone.now)

      # [{:appeal_id=>1, :appeal_type=>"Appeal", :power_of_attorney_name=>"Clarence Darrow"}, ...]
      warm_bgs_poa_and_return_cache_data(bgs_poa, claimant.decision_review_id, Appeal.name)
    end.compact

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {
      conflict_target: [:appeal_id, :appeal_type], columns: CACHED_APPEALS_BGS_POA_COLUMNS
    }

    datadog_report_time_segment(segment: "warm_poa_bgs_and_cache_ama", start_time: start_time)
  end

  def warm_poa_and_cache_ama_appeals_for_oldest_claimants
    start_time = Time.zone.now

    appeals_to_cache = oldest_claimants_with_poa.map do |claimant|
      bgs_poa = claimant.power_of_attorney
      claimant.update!(updated_at: Time.zone.now)

      # [{:appeal_id=>1, :appeal_type=>"Appeal", :power_of_attorney_name=>"Clarence Darrow"}, ...]
      warm_bgs_poa_and_return_cache_data(bgs_poa, claimant.decision_review_id, Appeal.name)
    end.compact

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {
      conflict_target: [:appeal_id, :appeal_type], columns: CACHED_APPEALS_BGS_POA_COLUMNS
    }

    datadog_report_time_segment(segment: "warm_poa_claimants_and_cache_ama", start_time: start_time)
  end

  def warm_poa_for_oldest_cached_records
    start_time = Time.zone.now
    oldest_bgs_poa_records.limit(1000).each do |bgs_poa|
      bgs_poa.save_with_updated_bgs_record! if bgs_poa.stale_attributes?
    end
    datadog_report_time_segment(segment: "warm_poa_bgs_oldest", start_time: start_time)
  end

  def legacy_appeal_ids_to_file_numbers(limit)
    # This block of code helps get file numbers associated with appeals in order to fetch poa
    appeals = LegacyAppeal.where(id: legacy_appeal_ids_with_hearings.first(limit))
    # => { "2096907"=>1, ...}
    vacols_ids_to_appeal_ids = appeals.pluck(:vacols_id, :id).to_h
    # => [["2096907", "543248948"],...]
    vacols_ids_to_bfcorlids = VACOLS::Case.where(bfkey: vacols_ids_to_appeal_ids.keys).pluck(:bfkey, :bfcorlid)
    # => {1=>"543248948", ...}
    vacols_ids_to_bfcorlids.map do |vacols_id, bfcorlid|
      [vacols_ids_to_appeal_ids[vacols_id], LegacyAppeal.veteran_file_number_from_bfcorlid(bfcorlid)]
    end.to_h
  end

  def fetch_bgs_power_of_attorney_by_file_number(file_number, appeal_id)
    return if file_number.blank?

    BgsPowerOfAttorney.find_or_create_by_file_number(file_number)
  rescue ActiveRecord::RecordInvalid # not found at BGS
    BgsPowerOfAttorney.new(file_number: file_number)
  rescue Errno::ECONNRESET, Savon::HTTPError => error
    warning_msgs << "#{LegacyAppeal.name} #{appeal_id}: #{error}" if warning_msgs.count < 100
    nil
  end

  def warm_bgs_poa_and_return_cache_data(bgs_poa, appeal_id, appeal_type)
    if bgs_poa&.stale_attributes?
      bgs_poa.save_with_updated_bgs_record!

      {
        appeal_id: appeal_id,
        appeal_type: appeal_type,
        power_of_attorney_name: bgs_poa&.representative_name
      }
    end
  rescue Errno::ECONNRESET, Savon::HTTPError => error
    warning_msgs << "#{appeal_type} #{appeal_id}: #{error}" if warning_msgs.count < 100
    nil
  end

  def log_warning
    slack_msg = warning_msgs.join("\n")
    slack_service.send_notification(slack_msg, "[WARN] WarmBgsCachesJob: first 100 warnings")
  end

  def legacy_appeal_ids_with_hearings
    sorted_active_schedule_hearing_tasks(LegacyAppeal.name).pluck(:appeal_id).uniq
  end

  def appeal_ids_with_hearings
    sorted_active_schedule_hearing_tasks(Appeal.name).pluck(:appeal_id).uniq
  end

  def sorted_active_schedule_hearing_tasks(appeal_type)
    tasks = active_schedule_hearing_tasks(appeal_type)
    tasks.order(Task.order_by_cached_appeal_priority_clause)
  end

  def active_schedule_hearing_tasks(appeal_type)
    ScheduleHearingTask.active.with_cached_appeals.where(appeal_type: appeal_type)
  end

  def claimants_for_open_appeals
    Claimant.where(decision_review_type: Appeal.name, decision_review_id: open_appeals_from_tasks)
  end

  def oldest_claimants_with_poa
    oldest_claimants_for_open_appeals.limit(1400).select { |claimant| claimant.power_of_attorney.present? }
  end

  def oldest_claimants_for_open_appeals
    claimants_for_open_appeals.order(updated_at: :asc)
  end

  def oldest_bgs_poa_records
    BgsPowerOfAttorney.order(last_synced_at: :asc)
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
    start_range = Time.zone.today.beginning_of_day
    end_range = start_range + 182.days

    ro_ids.each do |ro_id|
      regional_office = HearingDayMapper.validate_regional_office(ro_id)

      # Calling `quick_to_hash` here runs the code that will touch records that need
      # to be cached.
      HearingDayRange.new(start_range, end_range, regional_office)
        .all_hearing_days
        .map { |_hearing_day, scheduled_hearings| scheduled_hearings }
        .flatten
        .map { |hearing| hearing.quick_to_hash(RequestStore.store[:current_user].id) }
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

  def warm_attorney_address_caches
    start_time = Time.zone.now
    BgsAttorney.all.each(&:warm_address_cache)
    datadog_report_time_segment(segment: "warm_attorney_address_caches", start_time: start_time)
  end
end
