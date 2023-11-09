# frozen_string_literal: true

module Seeds
    class AppealsHeldByInactiveJudges < Base
      def initialize
        @legacy_appeals = []
        initial_file_number_and_participant_id
      end
  
      def seed!
        create_legacy_tasks
        create_ama_tasks
      end
  
      private
  
      def initial_file_number_and_participant_id
        @file_number ||= 201_000_001
        @participant_id ||= 600_000_000
        # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
        while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
          @file_number += 2000
          @participant_id += 2000
        end
      end
  
      def create_veteran(options = {})
        @file_number += 1
        @participant_id += 1
        params = {
          file_number: format("%<n>09d", n: @file_number),
          participant_id: format("%<n>09d", n: @participant_id)
        }
        create(:veteran, params.merge(options))
      end
  
      def create_legacy_tasks
        Timecop.travel(65.days.ago)
          create_legacy_appeals('RO17', 50)
        Timecop.return
      end

      def create_ama_tasks
        create_ama_appeals(50)
      end
  
      def create_vacols_entries(vacols_titrnum, docket_number, regional_office, type, judge, attorney, veteran)
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
            snamef: veteran.first_name,
            snamel: veteran.last_name,
            ssalut: ""
          )
        rescue ActiveRecord::RecordNotUnique
          retry if (retries += 1) < retry_max
        end
        sdomain_id = judge.css_id
        # Create the judge
        vacols_judge = create(
          :staff,
          :inactive_judge,
          sdomainid: sdomain_id
        )
        # Create the vacols_case
        begin
          retries ||= 0
          vacols_case = create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent, vacols_judge)
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
        create_tasks_for_legacy_appeals(legacy_appeal, attorney, judge)
  
        # Return the legacy_appeal
        legacy_appeal
      end
  
      def create_tasks_for_legacy_appeals(appeal, attorney, judge)
        # Will need a judge user for judge decision review task and an attorney user for the subsequent Attorney Task
        root_task = RootTask.find_or_create_by!(appeal: appeal)
      end

      # set judge to inactive
      def create_ineligible_judge(judge)
        judge.update!(active: false)
      end
      
      # AC1
      def create_legacy_appeals(regional_office, number_of_appeals_to_create)
        # The offset should start at 100 to avoid collisions
        offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a
        # Use a hearings user so the factories don't try to create one (and sometimes fail)
        inactive_judge = User.find_by_css_id("BVADSLADER")
        # call to make inactive
        create_ineligible_judge(judge)
        active_judge = User.find_by_css_id("BVAAABSHIRE")
        attorney = User.find_by_css_id("BVASCASPER1")
        # Set this for papertrail when creating vacols_case
        offsets.each do |offset|
          docket_number = "190000#{offset}"
          # Create the veteran for this legacy appeal
          veteran = create_veteran
  
          vacols_titrnum = "#{veteran.file_number}S"
  
          # Assign hearing type to video
          type = "video"
          
          # AC1: create legacy appeals ready to be distributed that have a hearing held by an inactive judge
          legacy_appeal = create_vacols_entries(vacols_titrnum, docket_number, regional_office, type, inactive_judge, attorney, veteran)
          # Create the task tree, need to create each task like this to avoid user creation and index conflicts
          create_legacy_appeals_decision_ready_for_dispatch(legacy_appeal, inactive_judge, attorney, veteran)
        end
      end

      # AC 2 and 3
      def create_ama_appeals(number_of_appeals_to_create)
        # The offset should start at 100 to avoid collisions
        offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a
        # Use a hearings user so the factories don't try to create one (and sometimes fail)
        active_judge = User.find_by_css_id("BVAAABSHIRE")
        attorney = User.find_by_css_id("BVASCASPER1")
      
        offsets.each do |offset|
          create_ama_appeals_decision_ready_dr_less_than_60_days(active_judge, attorney)
          create_ama_appeals_decision_ready_dr_more_than_60_days(active_judge, attorney)
        end
      end
  
      # Creates the video hearing request
      def create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent, vacols_judge)
        create(
          :case,
          :assigned,
          :video_hearing_requested,
          :type_original,
          user: vacols_judge,
          correspondent: correspondent,
          bfcorlid: vacols_titrnum,
          folder: vacols_folder,
          case_issues: [create(:case_issue, :compensation), create(:case_issue, :compensation), create(:case_issue, :compensation)]
        )
      end
      
      # Creates legacy appeal ready for dispatch and hearing
      def create_legacy_appeals_decision_ready_for_dispatch(legacy_appeal, judge, attorney, veteran)
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

        ## Hearing held by inactive judge
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: ""
        )
      end

      # AC2: ready to distribute for less than 60 days
      def create_ama_appeals_decision_ready_dr_less_than_60_days(judge, attorney)
        Timecop.travel(1.days.ago)
          appeal = create(:appeal,
                          :direct_review_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          veteran: create_veteran)
        Timecop.return
      end

      # AC3: ready to distribute for more than 60 days
      def create_ama_appeals_decision_ready_dr_more_than_60_days(judge, attorney)
        Timecop.travel(61.days.ago)
          appeal = create(:appeal,
                          :direct_review_docket,
                          :at_attorney_drafting,
                          associated_judge: judge,
                          associated_attorney: attorney,
                          veteran: create_veteran)
        Timecop.return
      end
    end
  end