# frozen_string_literal: true

# create Hearing seeds

module Seeds
  class Hearings < Base
    include PowerOfAttorneyMapper

    # Create the available hearing times and issue counts to pull from
    AMA_SCHEDULE_TIMES = %w[13:30 14:00 15:00 15:15 16:15].freeze # times in UTC
    LEGACY_SCHEDULE_TIMES = %w[8:15 9:30 10:15 11:00 11:45].freeze # times in EST
    ISSUE_COUNTS = %w[1 2 3 4 12].freeze

    # Define how many hearings per day and how many hearing days to create
    HEARINGS_PER_DAY = 3
    DEFAULT_COUNT = 5
    LARGE_COUNT = 90
    MEDIUM_COUNT = 20

    # Define the list of ROs with a large count of Days
    LARGE_RO_DAYS = %w[RO17].freeze

    # Define the list of ROs with a medium count of Days
    MEDIUM_RO_DAYS = %w[RO43].freeze

    def initialize
      @bfkey = 1234
      @bfcorkey = 5678
    end

    def seed!
      prev_user = RequestStore[:current_user]
      RequestStore[:current_user] = created_by_user
      create_hearing_days_with_hearings
      create_former_travel_currently_virtual_requested_legacy_appeals
      RequestStore[:current_user] = prev_user
    end

    private

    def create_ama_hearings_for_day(day, count)
      count.times do
        # Pick a random time from the list
        scheduled_time = AMA_SCHEDULE_TIMES[rand(0...AMA_SCHEDULE_TIMES.size)]

        # Pick a random issue count from the list
        issue_count = ISSUE_COUNTS[rand(0...ISSUE_COUNTS.size)]

        create_ama_hearing(day: day, scheduled_time_string_utc: scheduled_time, issue_count: issue_count.to_i)
      end
    end

    def create_legacy_hearings_for_day(day, count)
      count.times do
        # Pick a random time from the list
        scheduled_time = LEGACY_SCHEDULE_TIMES[rand(0...LEGACY_SCHEDULE_TIMES.size)]

        create_legacy_hearing(day: day, scheduled_time_string_est: scheduled_time)
      end
    end

    def create_mixed_legacy_ama_for_day(day)
      create_ama_hearings_for_day(day, 2)
      create_legacy_hearings_for_day(day, 2)
    end

    def get_next_hearing_day(hearing_day, index, offset)
      if index == 0
        Time.first_business_day(hearing_day)
      else
        next_hearing_day = (index * offset).days
        Time.first_business_day(hearing_day + next_hearing_day)
      end
    end

    def get_hearing_days_count(ro_key)
      if LARGE_RO_DAYS.include?(ro_key)
        LARGE_COUNT
      elsif MEDIUM_RO_DAYS.include?(ro_key)
        MEDIUM_COUNT
      else
        DEFAULT_COUNT
      end
    end

    def create_hearing_days_with_hearings
      # Create the list of ROs to generate hearing days
      ro_list = RegionalOffice.ros_with_hearings.merge("C" => RegionalOffice::CITIES["C"]).keys + ["R"]

      ro_list.each do |ro_key|
        # Default the hearing day to today
        scheduled_for = Time.zone.today

        # Set the count of hearing days to schedule for this RO
        count = get_hearing_days_count(ro_key)

        # Calculate the offset of days based on a 30 day month to spread the generated days
        offset = (30.to_f / count).ceil

        # Generate hearing days for each RO
        count.times do |index|
          # Get the next available hearing day factoring in the current index and date offset
          date = get_next_hearing_day(scheduled_for, index, offset)
          day = hearing_day_for_ro(ro_key: ro_key.to_s, scheduled_for: date)

          # Create full hearing days for the first 3 dates
          case index
          when 0
            create_ama_hearings_for_day(day, HEARINGS_PER_DAY)
          when 1
            create_legacy_hearings_for_day(day, HEARINGS_PER_DAY)
          when 2
            create_mixed_legacy_ama_for_day(day)
          end
        end
      end
    end

    def hearing_day_for_ro(ro_key:, scheduled_for:)
      HearingDay.create!(
        regional_office: %w[C R].include?(ro_key) ? nil : ro_key,
        room: (ro_key == "R") ? nil : Constants::HEARING_ROOMS_LIST.keys.sample,
        judge: random_judge_user,
        request_type: request_type_by_ro_key(ro_key),
        scheduled_for: scheduled_for,
        created_by: created_by_user,
        updated_by: created_by_user
      )
    end

    def request_type_by_ro_key(ro_key)
      if ro_key == "C"
        HearingDay::REQUEST_TYPES[:central]
      elsif ro_key == "R"
        HearingDay::REQUEST_TYPES[:virtual]
      elsif ro_key.starts_with?("RO")
        HearingDay::REQUEST_TYPES[:video]
      end
    end

    def random_judge_user
      User.find_by_css_id(%w[BVAAABSHIRE BVARERDMAN BVAEBECKER BVAKKEELING BVAAWAKEFIELD].sample)
    end

    def create_ama_appeal(issue_count: 1)
      veteran = create_veteran
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(claimant_participant_id: claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        veteran_is_not_claimant: Faker::Boolean.boolean,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_ama_hearing(day:, scheduled_time_string_utc:, issue_count: 1)
      appeal = create_ama_appeal(issue_count: issue_count)
      hearing = create(
        :hearing,
        hearing_day: day,
        appeal: appeal,
        bva_poc: created_by_user.full_name,
        scheduled_time: scheduled_time_string_utc
      )

      maybe_create_virtual_hearing(hearing)

      create_hearing_subtree(appeal, hearing)
    end

    def create_virtual_hearing(hearing)
      create(:virtual_hearing, :initialized, :all_emails_sent, hearing: hearing, status: :active)
    end

    def maybe_create_virtual_hearing(hearing)
      if hearing.hearing_day.request_type == HearingDay::REQUEST_TYPES[:virtual]
        create_virtual_hearing(hearing)
      elsif hearing.hearing_day.request_type == HearingDay::REQUEST_TYPES[:video]
        [0, 1].sample.times { create_virtual_hearing(hearing) }
      end
    end

    def create_poa(veteran_file_number: nil, claimant_participant_id: nil)
      fake_poa = Fakes::BGSServicePOA.random_poa_org[:power_of_attorney]

      create(
        :bgs_power_of_attorney,
        file_number: veteran_file_number,
        claimant_participant_id: claimant_participant_id,
        representative_name: fake_poa[:nm],
        poa_participant_id: fake_poa[:ptcpnt_id],
        representative_type: BGS_REP_TYPE_TO_REP_TYPE[fake_poa[:org_type_nm]]
      )
    end

    def create_legacy_appeal(hearing_day)
      @bfkey += 1
      @bfcorkey += 1
      vacols_case = create(
        :case,
        bfkey: @bfkey.to_s,
        bfcorkey: @bfcorkey.to_s,
        bfac: %w[1 3].sample, # original or Post remand,
        correspondent: create(:correspondent, stafkey: @bfcorkey.to_s)
      )

      file_number = LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
      create_veteran(veteran_file_number: file_number)
      create_poa(veteran_file_number: file_number)

      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: vacols_case,
        closest_regional_office: hearing_day.regional_office
      )
    end

    def create_legacy_hearing(day:, scheduled_time_string_est:)
      appeal = create_legacy_appeal(day)

      scheduled_for = HearingTimeService.legacy_formatted_scheduled_for(
        scheduled_for: day.scheduled_for.in_time_zone,
        scheduled_time_string: scheduled_time_string_est
      )

      case_hearing = create(
        :case_hearing,
        hearing_type: day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(scheduled_for),
        folder_nr: appeal.vacols_id,
        vdkey: day.id,
        board_member: day.judge.vacols_attorney_id.to_i
      )

      hearing = create(:legacy_hearing, case_hearing: case_hearing, hearing_day: day, appeal: appeal)
      maybe_create_virtual_hearing(hearing)
      create_hearing_subtree(appeal, hearing)
    end

    def created_by_user
      @created_by_user ||= User.find_or_create_by(css_id: "BVASYELLOW", station_id: "101")
    end

    # rubocop:disable Metrics/MethodLength
    def create_hearing_subtree(appeal, hearing)
      root_task = create(:root_task, appeal: appeal)
      distribution_task = create(
        :distribution_task,
        appeal: appeal,
        parent: root_task
      )
      parent_hearing_task = create(
        :hearing_task,
        parent: distribution_task,
        appeal: appeal
      )

      create(
        :schedule_hearing_task,
        :completed,
        parent: parent_hearing_task,
        appeal: appeal
      )
      create(
        :assign_hearing_disposition_task,
        :in_progress,
        parent: parent_hearing_task,
        appeal: appeal
      )

      TrackVeteranTask.sync_tracking_tasks(appeal)

      create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: parent_hearing_task
      )
    end
    # rubocop:enable Metrics/MethodLength

    # creates fake veteran given a file number
    def create_veteran(veteran_file_number: nil)
      veteran_fields = {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        bgs_veteran_record: {
          date_of_birth: Faker::Date.birthday(min_age: 35, max_age: 80).strftime("%m/%d/%Y"),
          date_of_death: nil,
          name_suffix: nil,
          sex: Faker::Gender.binary_type[0],
          address_line1: Faker::Address.street_address,
          country: "USA",
          zip_code: Faker::Address.zip_code,
          state: Faker::Address.state_abbr,
          city: Faker::Address.city
        }
      }
      veteran_fields[:file_number] = veteran_file_number if veteran_file_number.present?

      create(
        :veteran,
        **veteran_fields
      )
    end

    def create_travel_board_vacols_case
      @bfkey += 1
      @bfcorkey += 1
      create(
        :case,
        :travel_board_hearing,
        bfkey: @bfkey.to_s,
        bfcorkey: @bfcorkey.to_s,
        correspondent: create(:correspondent, stafkey: @bfcorkey.to_s)
      )
    end

    def create_former_travel_currently_virtual_requested_legacy_appeals
      16.times do
        vacols_case = create_travel_board_vacols_case

        veteran = create_veteran(
          veteran_file_number: LegacyAppeal.veteran_file_number_from_bfcorlid(vacols_case.bfcorlid)
        )

        create_poa(veteran_file_number: veteran.file_number)

        create(
          :schedule_hearing_task,
          appeal: create(
            :legacy_appeal,
            :with_veteran,
            vacols_case: vacols_case,
            closest_regional_office: nil,
            changed_hearing_request_type: "R"
          )
        )
      end
    end
  end
end
