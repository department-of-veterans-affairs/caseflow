# frozen_string_literal: true

require_relative "./helpers/seed_helpers"

module Seeds
  class RemandedLegacyAppeals < Base
    include SeedHelpers

    def initialize
      @legacy_appeals = []
      initial_file_number_and_participant_id
    end

    def seed!
      create_legacy_tasks
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 200_000_000
      @participant_id ||= 600_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_legacy_tasks
      Timecop.travel(65.days.ago)
        create_legacy_appeals('RO17', 50, 'decision_ready_hr')
      Timecop.return

      # Not Needed for Remand Reasons Demo Testing
      # Timecop.travel(50.days.ago)
      #   create_legacy_appeals('RO17', 30, 'ready_for_dispatch')
      # Timecop.return
    end

    def create_vacols_entries(vacols_titrnum, docket_number, regional_office, type, judge, attorney, workflow)
      # We need these retries because the sequence for FactoryBot comes out of
      # sync with what's in the DB. This just essentially updates the FactoryBot
      # sequence to match what's in the DB.
      # Note: Because the sequences in FactoryBot are global, these retrys won't happen
      #   every time you call this, probably only the first time.
      retry_max = 100

      # Create the vacols_folder
      begin
        retries ||= 0
        vacols_folder = create(
          :folder,
          tinum: docket_number,
          titrnum: vacols_titrnum
        )
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the correspondent (where the name in the UI comes from)
      begin
        retries ||= 0
        correspondent = create(
          :correspondent,
          snamef: Faker::Name.first_name,
          snamel: Faker::Name.last_name,
          ssalut: ""
        )
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      sdomain_id = workflow === 'decision_ready_hr' ? attorney.css_id : judge.css_id
      # Create the vacols_case
      begin
        retries ||= 0
        if type == "video"
          vacols_case = create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
          create(:staff, slogid: vacols_case.bfcurloc, sdomainid: sdomain_id)
        elsif type == "travel"
          vacols_case = create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
          create(:staff, slogid: vacols_case.bfcurloc, sdomainid: sdomain_id)
        end
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the legacy_appeal, this doesn't fail with index problems, so no need to retry
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )
      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)
      create_tasks_for_legacy_appeals(legacy_appeal, attorney, judge, workflow)

      # Return the legacy_appeal
      legacy_appeal
    end

    def create_tasks_for_legacy_appeals(appeal, attorney, judge, workflow)
      # Will need a judge user for judge decision review task and an attorney user for the subsequent Attorney Task
      root_task = RootTask.find_or_create_by!(appeal: appeal)
    end

    def create_legacy_appeals(regional_office, number_of_appeals_to_create, workflow)
      # The offset should start at 100 to avoid collisions
      offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a
      # Use a hearings user so the factories don't try to create one (and sometimes fail)
      judge = User.find_by_css_id("BVAAABSHIRE")
      attorney = User.find_by_css_id("BVASCASPER1")
      # Set this for papertrail when creating vacols_case
      offsets.each do |offset|
        docket_number = "190000#{offset}"
        # Create the veteran for this legacy appeal
        veteran = create_veteran

        vacols_titrnum = "#{veteran.file_number}S"

        # Create some video and some travel hearings
        type = offset.even? ? "travel" : "video"

        if(workflow === 'decision_ready_hr')
          legacy_appeal = create_vacols_entries(vacols_titrnum, docket_number, regional_office, type, judge, attorney, workflow)
          # Create the task tree, need to create each task like this to avoid user creation and index conflicts
          create_legacy_appeals_decision_ready_hr(legacy_appeal, judge, attorney)
        end
        if(workflow === 'ready_for_dispatch')
          legacy_appeal = create_vacols_entries(vacols_titrnum, docket_number, regional_office, type, judge, attorney, workflow)
          # Create the task tree, need to create each task like this to avoid user creation and index conflicts
          create_legacy_appeals_decision_ready_for_dispatch(legacy_appeal, judge, attorney)
        end
      end
    end

    # Creates the video hearing request
    def create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      create(
        :case,
        :assigned,
        :video_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder,
        case_issues: [create(:case_issue, :compensation), create(:case_issue, :compensation), create(:case_issue, :compensation)]
      )
    end

    # Creates the Travel Board hearing request
    def create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      create(
        :case,
        :assigned,
        :travel_board_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder,
        case_issues: [create(:case_issue, :compensation), create(:case_issue, :compensation), create(:case_issue, :compensation)]
      )
    end

    def create_legacy_appeals_decision_ready_hr(legacy_appeal, judge, attorney)
      vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      created_at = legacy_appeal[:created_at]
      task_id = "#{legacy_appeal.vacols_id}-#{VacolsHelper.day_only_str(created_at)}"
      create(
        :attorney_case_review,
        appeal: legacy_appeal,
        reviewing_judge: judge,
        attorney: attorney,
        task_id: task_id,
        note: Faker::Lorem.sentence
      )
    end

    def create_legacy_appeals_decision_ready_for_dispatch(legacy_appeal, judge, attorney)
      vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      created_at = legacy_appeal[:created_at]
      task_id = "#{legacy_appeal.vacols_id}-#{VacolsHelper.day_only_str(created_at)}"

      ## Judge Case Review
      create(
        :judge_case_review,
        appeal: legacy_appeal,
        judge: judge,
        attorney: attorney,
        task_id: task_id,
        location: "bva_dispatch",
        issues: []
      )
    end
  end
end
