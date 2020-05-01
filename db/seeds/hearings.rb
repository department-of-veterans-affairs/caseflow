# frozen_string_literal: true

module Seeds
  class Hearings < Base
    def seed!
      prev_user = RequestStore[:current_user]
      RequestStore[:current_user] = created_by_user
      create_hearing_days
      create_ama_hearing_appeals
      RequestStore[:current_user] = prev_user
    end

    private

    # rubocop:disable Metrics/MethodLength
    def create_ama_hearing(day)
      veteran = create(
        :veteran,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )

      appeal = create(
        :appeal,
        veteran_file_number: veteran.file_number,
        claimants: [create(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")],
        docket_type: Constants.AMA_DOCKETS.hearing
      )

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

      hearing = create(
        :hearing,
        hearing_day: day,
        appeal: appeal,
        bva_poc: User.find_by_css_id("BVAAABSHIRE").full_name,
        scheduled_time: "9:00AM"
      )

      create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: parent_hearing_task
      )
    end
    # rubocop:enable Metrics/MethodLength

    def create_case_hearing(day, ro_key)
      folder_map = {
        "RO17" => "3620725",
        "RO45" => "3411278",
        "C" => "3542942"
      }

      create(
        :case_hearing,
        folder_nr: folder_map[ro_key],
        vdkey: day.id,
        board_member: User.find_by_css_id("BVAAABSHIRE").vacols_attorney_id.to_i
      )
    end

    def created_by_user
      @created_by_user ||= User.find_or_create_by(css_id: "BVATWARNER", station_id: "101")
    end

    # rubocop:disable Metrics/MethodLength
    def create_hearing_days
      %w[C RO17 RO19 RO31 RO43 RO45].each do |ro_key|
        (1..5).each do |index|
          day = HearingDay.create!(
            regional_office: (ro_key == "C") ? nil : ro_key,
            room: "1",
            judge: User.find_by_css_id("BVAAABSHIRE"),
            request_type: (ro_key == "C") ? "C" : "V",
            scheduled_for: Time.zone.today + (index * 11).days,
            created_by: created_by_user,
            updated_by: created_by_user
          )

          case index
          when 1
            create_ama_hearing(day)
          when 2
            create_case_hearing(day, ro_key)
          when 3
            create_case_hearing(day, ro_key)
            create_ama_hearing(day)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def create_ama_hearing_appeals
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"

      create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: "808415990",
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 1, :rating, contested_issue_description: description, notes: notes
        )
      )
      create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: "992190636",
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 8, :rating, contested_issue_description: description, notes: notes
        )
      )

      user = User.find_by(css_id: "BVATWARNER")
      HearingDay.create(
        regional_office: "RO17",
        request_type: "V",
        scheduled_for: 5.days.from_now,
        room: "001",
        created_by: user,
        updated_by: user
      )
    end
    # rubocop:enable Metrics/MethodLength

    def create_previously_held_hearing_data
      user = User.find_by_css_id("BVAAABSHIRE")
      appeal = LegacyAppeal.find_or_create_by(vacols_id: "3617215", vbms_id: "994806951S")

      return if ([appeal.type] - ["Post Remand", "Original"]).empty? &&
                appeal.hearings.map(&:disposition).include?(:held)

      create(:case_hearing, :disposition_held, user: user, folder_nr: appeal.vacols_id)
    end
  end
end
