# frozen_string_literal: true

module Seeds
  class Hearings
    def seed!
      create_hearing_days
    end

    private

    def create_ama_hearing(day)
      veteran = FactoryBot.create(
        :veteran,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )
  
      appeal = FactoryBot.create(
        :appeal,
        veteran_file_number: veteran.file_number,
        claimants: [FactoryBot.create(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO")],
        docket_type: Constants.AMA_DOCKETS.hearing
      )
  
      root_task = FactoryBot.create(:root_task, appeal: appeal)
      distribution_task = FactoryBot.create(
        :distribution_task,
        appeal: appeal,
        parent: root_task
      )
      parent_hearing_task = FactoryBot.create(
        :hearing_task,
        parent: distribution_task,
        appeal: appeal
      )
  
      FactoryBot.create(
        :schedule_hearing_task,
        :completed,
        parent: parent_hearing_task,
        appeal: appeal
      )
      FactoryBot.create(
        :assign_hearing_disposition_task,
        :in_progress,
        parent: parent_hearing_task,
        appeal: appeal
      )
  
      TrackVeteranTask.sync_tracking_tasks(appeal)
  
      hearing = FactoryBot.create(
        :hearing,
        hearing_day: day,
        appeal: appeal,
        bva_poc: User.find_by_css_id("BVAAABSHIRE").full_name,
        scheduled_time: "9:00AM"
      )
  
      FactoryBot.create(
        :hearing_task_association,
        hearing: hearing,
        hearing_task: parent_hearing_task
      )
    end
  
    def create_case_hearing(day, ro_key)
      case ro_key
      when "RO17"
        folder_nr = "3620725"
      when "RO45"
        folder_nr = "3411278"
      when "C"
        folder_nr = "3542942"
      end
  
      FactoryBot.create(
        :case_hearing,
        folder_nr: folder_nr,
        vdkey: day.id,
        board_member: User.find_by_css_id("BVAAABSHIRE").vacols_attorney_id.to_i
      )
    end
  
    def create_hearing_days
      user = User.find_by(css_id: "BVATWARNER")
  
      # Set the current user var here, which is used to populate the
      # created by field.
      RequestStore[:current_user] = user
  
      %w[C RO17 RO19 RO31 RO43 RO45].each do |ro_key|
        (1..5).each do |index|
          day = HearingDay.create!(
            regional_office: (ro_key == "C") ? nil : ro_key,
            room: "1",
            judge: User.find_by_css_id("BVAAABSHIRE"),
            request_type: (ro_key == "C") ? "C" : "V",
            scheduled_for: Time.zone.today + (index * 11).days,
            created_by: user,
            updated_by: user
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
  
      # The current user var should be set to nil at the start of this
      # function. Restore it before executing the next seed function.
      RequestStore[:current_user] = nil
    end
  end
end
