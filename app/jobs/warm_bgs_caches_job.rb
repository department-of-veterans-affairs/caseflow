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

  LIMITS = {
    PRIORITY: 1_000,
    MOST_RECENT: 500,
    OLDEST_CLAIMANT: 1_400,
    OLDEST_CACHED: 1_000,
    PEOPLE: 12_000
  }.freeze

  def warm_poa_caches
    # We do 4 passes to update our POA cache (bgs_power_of_attorney table).
    # 1. Look at 2000 poa (LIMITS[:PRIORITY] for legacy + ama) record in a hearings priority order and
    #    update and cache in CachedAppeal
    # 2. Look at 1000 poa (LIMITS[:MOST_RECENT] for legacy + ama) record appeals with most recently
    #    assigned ScheduleHearingTask and update and cache in CachedAppeal
    # 3. Look at 1400 (LIMITS[:OLDEST_CLAIMANT]) Claimants w/o POA associated record and create
    #    cached record and cache in CachedAppeal
    # 4. Look at the 1000 LIMITS[:OLDEST_CACHED]) oldest cached records and update them

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
    warm_poa_and_cache_for_appeals_for_hearings_priority
    warm_poa_and_cache_for_appeals_for_hearings_most_recent
    warm_poa_and_cache_ama_appeals_for_oldest_claimants
    warm_poa_for_oldest_cached_records

    log_warning unless warning_msgs.empty?
  rescue StandardError => error
    capture_exception(error: error)
  end

  # Warm POA and cache 2000(legacy + ama) appeals with active ScheduleHearingTask in the priority
  # they're displayed in the Assign Hearings table.
  def warm_poa_and_cache_for_appeals_for_hearings_priority
    legacy_start_time = Time.zone.now
    legacy_appeals = LegacyAppeal.where(id: priority_appeal_ids(LegacyAppeal.name).first(LIMITS[:PRIORITY]))
    legacy_datadog_segment = "warm_poa_bgs_and_cache_legacy_priority"
    warm_poa_and_cache_for_legacy_appeals(legacy_appeals, legacy_start_time, legacy_datadog_segment)

    ama_start_time = Time.zone.now
    claimants_for_hearing = Claimant.where(
      decision_review_type: Appeal.name,
      decision_review_id: most_recent_appeal_ids(Appeal.name).first(LIMITS[:PRIORITY])
    )
    ama_datadog_segment = "warm_poa_bgs_and_cache_ama_priority"
    warm_poa_and_cache_for_ama_appeals(claimants_for_hearing, ama_start_time, ama_datadog_segment)
  end

  # Warm POA and cache 1000(legacy + ama) appeals with active ScheduleHearingTask that have
  # most recently been assigned. This ensures that we're caching poa names for all the new
  # tasks that are coming into the table. Data shows that about on average a total of 200
  # ScheduleHearingTasks are assigned daily so 1000 gives enough padding.
  def warm_poa_and_cache_for_appeals_for_hearings_most_recent
    legacy_start_time = Time.zone.now
    legacy_appeals = LegacyAppeal.where(id: most_recent_appeal_ids(LegacyAppeal.name).first(LIMITS[:MOST_RECENT]))
    legacy_datadog_segment = "warm_poa_bgs_and_cache_legacy_recent"
    warm_poa_and_cache_for_legacy_appeals(legacy_appeals, legacy_start_time, legacy_datadog_segment)

    ama_start_time = Time.zone.now
    claimants_for_hearing = Claimant.where(
      decision_review_type: Appeal.name,
      decision_review_id: most_recent_appeal_ids(Appeal.name).first(LIMITS[:MOST_RECENT])
    )
    ama_datadog_segment = "warm_poa_bgs_and_cache_ama_recent"
    warm_poa_and_cache_for_ama_appeals(claimants_for_hearing, ama_start_time, ama_datadog_segment)
  end

  # Warm POA for claimants that haven't been updated in a while and since we're warming, let's
  # also cache the appeal.
  def warm_poa_and_cache_ama_appeals_for_oldest_claimants
    start_time = Time.zone.now
    datadog_segment = "warm_poa_claimants_and_cache_ama"
    warm_poa_and_cache_for_ama_appeals(oldest_claimants_with_poa, start_time, datadog_segment)
  end

  # Warm POA records that haven't been synced in a while.
  def warm_poa_for_oldest_cached_records
    start_time = Time.zone.now
    oldest_bgs_poa_records.limit(LIMITS[:OLDEST_CACHED]).each do |bgs_poa|
      begin
        bgs_poa.save_with_updated_bgs_record! if bgs_poa.stale_attributes?
      rescue Errno::ECONNRESET, Savon::HTTPError
        # do nothing
      rescue StandardError => error
        capture_exception(error: error)
      end
    end
    datadog_report_time_segment(segment: "warm_poa_bgs_oldest", start_time: start_time)
  end

  def warm_poa_and_cache_for_legacy_appeals(legacy_appeals, start_time, datadog_segment)
    appeals_to_cache = legacy_appeal_ids_to_file_numbers(legacy_appeals).map do |appeal_id, file_number|
      bgs_poa = fetch_bgs_power_of_attorney_by_file_number(file_number, appeal_id)

      # [{:appeal_id=>1, :appeal_type=>"LegacyAppeal", :power_of_attorney_name=>"Clarence Darrow"}, ...]
      warm_bgs_poa_and_return_cache_data(bgs_poa, appeal_id, LegacyAppeal.name)
    end.compact

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {
      conflict_target: [:appeal_id, :appeal_type], columns: CACHED_APPEALS_BGS_POA_COLUMNS
    }

    datadog_report_time_segment(segment: datadog_segment, start_time: start_time)
  end

  def warm_poa_and_cache_for_ama_appeals(claimants, start_time, datadog_segment)
    appeals_to_cache = claimants.map do |claimant|
      bgs_poa = claimant_poa_or_nil(claimant)
      claimant.update!(updated_at: Time.zone.now)

      # [{:appeal_id=>1, :appeal_type=>"Appeal", :power_of_attorney_name=>"Clarence Darrow"}, ...]
      warm_bgs_poa_and_return_cache_data(bgs_poa, claimant.decision_review_id, Appeal.name)
    end.compact

    CachedAppeal.import appeals_to_cache, on_duplicate_key_update: {
      conflict_target: [:appeal_id, :appeal_type], columns: CACHED_APPEALS_BGS_POA_COLUMNS
    }

    datadog_report_time_segment(segment: datadog_segment, start_time: start_time)
  end

  # This block of code helps get file numbers associated with appeals in order to fetch poa
  def legacy_appeal_ids_to_file_numbers(legacy_appeals)
    # => { "2096907"=>1, ...}
    vacols_ids_to_appeal_ids = legacy_appeals.pluck(:vacols_id, :id).to_h
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
  rescue StandardError => error
    add_warning_msg("#{LegacyAppeal.name} #{appeal_id}: #{error}")
    nil
  end

  def warm_bgs_poa_and_return_cache_data(bgs_poa, appeal_id, appeal_type)
    bgs_poa.save_with_updated_bgs_record! if bgs_poa&.stale_attributes?

    {
      appeal_id: appeal_id,
      appeal_type: appeal_type,
      power_of_attorney_name: bgs_poa&.representative_name
    }
  rescue StandardError => error
    add_warning_msg("#{appeal_type} #{appeal_id}: #{error}")
    nil
  end

  def add_warning_msg(msg)
    warning_msgs << msg if warning_msgs.count < 100
  end

  def log_warning
    slack_msg = warning_msgs.join("\n")
    slack_service.send_notification(slack_msg, "[WARN] WarmBgsCachesJob: first 100 warnings")
  end

  def priority_appeal_ids(appeal_type)
    tasks = ScheduleHearingTask.active.with_cached_appeals.where(appeal_type: appeal_type)
    tasks.order(Task.order_by_cached_appeal_priority_clause).pluck(:appeal_id).uniq
  end

  def most_recent_appeal_ids(appeal_type)
    ScheduleHearingTask.active.where(appeal_type: appeal_type).order(assigned_at: :desc).pluck(:appeal_id).uniq
  end

  def claimants_for_open_appeals
    Claimant.where(decision_review_type: Appeal.name, decision_review_id: open_appeals_from_tasks)
  end

  def oldest_claimants_with_poa
    oldest_claimants_for_open_appeals.limit(LIMITS[:OLDEST_CLAIMANT])
      .select { |claimant| claimant_poa_or_nil(claimant).present? }
  end

  def oldest_claimants_for_open_appeals
    claimants_for_open_appeals.order(updated_at: :asc)
  end

  def claimant_poa_or_nil(claimant)
    claimant.power_of_attorney
  rescue StandardError => error
    add_warning_msg("#{Appeal.name} #{claimant.decision_review_id}: #{error}")
    nil # returning nil here to allow job to continue; this does not mean that claimant is missing POA
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
      .limit(LIMITS[:PEOPLE])
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
