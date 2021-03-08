# frozen_string_literal: true

# create Hearing seeds

module Seeds
  class Hearings < Base
    include PowerOfAttorneyMapper

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

    def create_ama_hearings_for_day(day)
      create_ama_hearing(day: day, scheduled_time_string_utc: "14:00", issue_count: 1) # 9:00AM ET
      create_ama_hearing(day: day, scheduled_time_string_utc: "15:00", issue_count: 3) # 10:00AM ET
      create_ama_hearing(day: day, scheduled_time_string_utc: "16:15", issue_count: 4) # 11:15AM ET
    end

    def create_legacy_hearings_for_day(day)
      create_legacy_hearing(day: day, scheduled_time_string_est: "8:15") # 8:30AM ET
      create_legacy_hearing(day: day, scheduled_time_string_est: "9:30") # 9:30AM ET
      create_legacy_hearing(day: day, scheduled_time_string_est: "10:15") # 10:30AM ET
    end

    def create_mixed_legacy_ama_for_day(day)
      create_ama_hearing(day: day, scheduled_time_string_utc: "13:30", issue_count: 4) # 8:30AM ET
      create_ama_hearing(day: day, scheduled_time_string_utc: "15:15", issue_count: 12) # 10:15AM ET
      create_legacy_hearing(day: day, scheduled_time_string_est: "13:00") # 1:00PM ET
      create_legacy_hearing(day: day, scheduled_time_string_est: "14:00") # 2:00PM ET
    end

    def create_hearing_days_with_hearings
      %w[C R RO17 RO19 RO31 RO43 RO45].each do |ro_key|
        day = hearing_day_for_ro(ro_key: ro_key, scheduled_for: Time.zone.today)
        create_ama_hearings_for_day(day)

        day = hearing_day_for_ro(ro_key: ro_key, scheduled_for: Time.zone.today + 11.days)
        create_legacy_hearings_for_day(day)

        day = hearing_day_for_ro(ro_key: ro_key, scheduled_for: Time.zone.today + 22.days)
        create_mixed_legacy_ama_for_day(day)

        hearing_day_for_ro(ro_key: ro_key, scheduled_for: Time.zone.today + 33.days)
        hearing_day_for_ro(ro_key: ro_key, scheduled_for: Time.zone.today + 44.days)
      end
    end

    def hearing_day_for_ro(ro_key:, scheduled_for:)
      HearingDay.create!(
        regional_office: (ro_key == "C" || ro_key == "R") ? nil : ro_key,
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
      ro_key = "R" # virtual
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
            closest_regional_office: ro_key,
            changed_request_type: "R"
          )
        )
      end
    end
  end
end
