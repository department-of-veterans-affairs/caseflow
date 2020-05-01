# frozen_string_literal: true

module Seeds
  class Tasks < Base
    def seed!
      create_tasks
    end

    private

    def create_tasks
      create_ama_distribution_tasks
      create_bva_dispatch_user_with_tasks
      create_qr_tasks
      create_different_hearings_tasks
      create_change_hearing_disposition_task
    end

    def create_ama_distribution_tasks
      veteran = FactoryBot.create(:veteran, first_name: "Julius", last_name: "Hodge")
      appeal = FactoryBot.create(:appeal, veteran: veteran, docket_type: Constants.AMA_DOCKETS.evidence_submission)
      FactoryBot.create(
        :request_issue,
        :nonrating,
        notes: "Pain disorder with 100\% evaluation per examination",
        decision_review: appeal
      )
  
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
  
      # Completing the evidence submission task will mark the appeal ready for distribution
      evidence_submission_task = EvidenceSubmissionWindowTask.find_by(appeal: appeal)
      evidence_submission_task.when_timer_ends
    end

    def create_qr_tasks
      # Create QR tasks; one assigned just to the QR org and three assigned both to the org and a QR user.
      create_task_at_quality_review
      create_task_at_quality_review("Jane Judge_CaseAtQR Michael", "Joan Attorney_CaseAtQR Ly")
      create_task_at_quality_review("Cosette Judge_CaseAtQR Zepeda", "Lian Attorney_CaseAtQR Arroyo")
      create_task_at_quality_review("Huilen Judge_CaseAtQR Concepcion", "Ilva Attorney_CaseAtQR Urrutia")
    end

    def qr_user
      @qr_user ||= User.find_by_css_id "QR_USER" # must already exist
    end

    def create_bva_dispatch_user_with_tasks
      u = User.find_by(css_id: "BVAGWHITE")
      BvaDispatch.singleton.add_user(u)

      [42, 66, 13].each do |rand_seed|
        create_task_at_bva_dispatch(rand_seed)
      end
    end

    def create_task_at_bva_dispatch(seed = Faker::Number.number(digits: 3))
      Faker::Config.random = Random.new(seed)
      vet = FactoryBot.create(
        :veteran,
        file_number: Faker::Number.number(digits: 9).to_s,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )
  
      notes = "Pain disorder with 100\% evaluation per examination"
  
      appeal = FactoryBot.create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: FactoryBot.create_list(
          :request_issue, 1, :nonrating, notes: notes
        )
      )
  
      root_task = appeal.root_task
      judge = FactoryBot.create(:user, station_id: 101, full_name: "Apurva Judge_CaseAtDispatch Wakefield")
      FactoryBot.create(:staff, :judge_role, user: judge)
      judge_task = FactoryBot.create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: root_task
      )
  
      atty = FactoryBot.create(:user, station_id: 101, full_name: "Andy Attorney_CaseAtDispatch Belanger")
      FactoryBot.create(:staff, :attorney_role, user: atty)
      atty_task = FactoryBot.create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: atty,
        assigned_by: judge,
        parent: judge_task,
        appeal: appeal
      )
  
      judge_team = JudgeTeam.create_for_judge(judge)
      judge_team.add_user(atty)
  
      appeal.request_issues.each do |request_issue|
        FactoryBot.create(
          :decision_issue,
          :nonrating,
          disposition: "allowed",
          decision_review: appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 2.months.ago,
          benefit_type: request_issue.benefit_type
        )
      end
  
      atty_task.update!(status: Constants.TASK_STATUSES.completed)
      judge_task.update!(status: Constants.TASK_STATUSES.completed)
  
      BvaDispatchTask.create_from_root_task(root_task)
    end

    def create_task_at_quality_review(judge_name = "Madhu Judge_CaseAtQR Burnham", attorney_name = "Bailey Attorney_CaseAtQR Eoin")
      vet = FactoryBot.create(
        :veteran,
        file_number: Faker::Number.number(digits: 9).to_s,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )
      notes = "Pain disorder with 100\% evaluation per examination"
  
      appeal = FactoryBot.create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.direct_review,
        closest_regional_office: "RO17",
        request_issues: FactoryBot.create_list(
          :request_issue, 1, :nonrating, notes: notes
        )
      )
      root_task = appeal.root_task
  
      judge = FactoryBot.create(:user, station_id: 101)
      judge.update!(full_name: judge_name) if judge_name
      FactoryBot.create(:staff, :judge_role, user: judge)
      judge_task = JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge)
  
      atty = FactoryBot.create(:user, station_id: 101)
      atty.update!(full_name: attorney_name) if attorney_name
      FactoryBot.create(:staff, :attorney_role, user: atty)
      atty_task_params = { appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }
      atty_task = AttorneyTask.create!(atty_task_params)
  
      atty_task.update!(status: Constants.TASK_STATUSES.completed)
      judge_task.update!(status: Constants.TASK_STATUSES.completed)
  
      qr_org_task = QualityReviewTask.create_from_root_task(root_task)
  
      if judge_name == "Madhu Judge_CaseAtQR Burnham" # default
        qr_task_params = [{
          appeal: appeal,
          parent_id: qr_org_task.id,
          assigned_to_id: qr_user.id,
          assigned_to_type: qr_user.class.name,
          assigned_by: qr_user
        }]
        QualityReviewTask.create_many_from_params(qr_task_params, qr_user).first
      end
    end

    def create_different_hearings_tasks
      (%w[RO17 RO19 RO31 RO43 RO45] + [nil]).each do |regional_office|
        create_legacy_case_with_open_schedule_hearing_task(regional_office)
  
        30.times do
          appeal = FactoryBot.create(
            :appeal,
            :hearing_docket,
            claimants: [
              FactoryBot.create(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO_#{rand(10**10)}")
            ],
            closest_regional_office: regional_office
          )
  
          FactoryBot.create(:available_hearing_locations, regional_office, appeal: appeal)
  
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
  
          schedule_hearing_task_status = [:completed, :in_progress].sample
  
          FactoryBot.create(
            :schedule_hearing_task,
            schedule_hearing_task_status,
            parent: parent_hearing_task,
            appeal: appeal
          )
  
          # For completed hearing tasks, generate additional tasks too.
          next unless schedule_hearing_task_status == :completed
  
          disposition_task = FactoryBot.create(
            :assign_hearing_disposition_task,
            parent: parent_hearing_task,
            appeal: appeal
          )
          FactoryBot.create(
            [:no_show_hearing_task, :evidence_submission_window_task].sample,
            parent: disposition_task,
            appeal: appeal
          )
        end
      end
    end

    def create_change_hearing_disposition_task
      hearings_member = User.find_or_create_by(css_id: "BVATWARNER", station_id: 101)
      hearing_day = FactoryBot.create(:hearing_day, created_by: hearings_member, updated_by: hearings_member)
      veteran = FactoryBot.create(:veteran, first_name: "Abellona", last_name: "Valtas", file_number: 123_456_789)
      appeal = FactoryBot.create(:appeal, :hearing_docket, veteran_file_number: veteran.file_number)
      root_task = FactoryBot.create(:root_task, appeal: appeal)
      distribution_task = FactoryBot.create(:distribution_task, parent: root_task)
      parent_hearing_task = FactoryBot.create(:hearing_task, parent: distribution_task)
      FactoryBot.create(:assign_hearing_disposition_task, parent: parent_hearing_task)
  
      hearing = FactoryBot.create(
        :hearing,
        appeal: appeal,
        hearing_day: hearing_day,
        created_by: hearings_member,
        updated_by: hearings_member
      )
      FactoryBot.create(:hearing_task_association, hearing: hearing, hearing_task: parent_hearing_task)
      FactoryBot.create(:change_hearing_disposition_task, parent: parent_hearing_task)
    end

    def create_legacy_case_with_open_schedule_hearing_task(ro_key)
      case ro_key
      when "RO17"
        vacols_id = "2668454"
      when "RO45"
        vacols_id = "3261587"
      when nil
        vacols_id = "3019752"
      end
  
      LegacyAppeal.find_or_create_by_vacols_id(vacols_id) if vacols_id.present?
    rescue ActiveRecord::RecordNotFound
      puts "Could not load FACOLS record for vacols_id #{vacols_id} -- are FACOLS seeds present?"
    end
  end
end
