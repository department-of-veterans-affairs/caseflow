# frozen_string_literal: true

module Seeds
  class Tasks < Base
    def initialize
      @ama_appeals = []
    end

    def seed!
      create_ama_appeals
      create_tasks
      create_legacy_issues_eligible_for_opt_in # TODO move to Seeds::Intake
    end

    private

    def create_ama_appeals
      notes = "Pain disorder with 100\% evaluation per examination"

      FactoryBot.create(
        :appeal,
        claimants: [
          FactoryBot.build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO"),
          FactoryBot.build(:claimant, participant_id: "OTHER_CLAIMANT")
        ],
        veteran_file_number: "701305078",
        docket_type: Constants.AMA_DOCKETS.direct_review,
        request_issues: FactoryBot.create_list(:request_issue, 3, :nonrating, notes: notes)
      )

      es = Constants.AMA_DOCKETS.evidence_submission
      dr = Constants.AMA_DOCKETS.direct_review
      # Older style, tasks to be created later
      [
        { number_of_claimants: nil, veteran_file_number: "783740847", docket_type: es, request_issue_count: 3 },
        { number_of_claimants: 1, veteran_file_number: "228081153", docket_type: es, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "152003980", docket_type: dr, request_issue_count: 3 },
        { number_of_claimants: 1, veteran_file_number: "375273128", docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "682007349", docket_type: dr, request_issue_count: 5 },
        { number_of_claimants: 1, veteran_file_number: "231439628", docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "975191063", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "662643660", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "162726229", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "760362568", docket_type: dr, request_issue_count: 8 }
      ].each do |params|
        @ama_appeals << FactoryBot.create(
          :appeal,
          number_of_claimants: params[:number_of_claimants],
          veteran_file_number: params[:veteran_file_number],
          docket_type: params[:docket_type],
          request_issues: FactoryBot.create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end

      # Newer style, tasks created through the Factory trait
      [
        { number_of_claimants: nil, veteran_file_number: "963360019", docket_type: dr, request_issue_count: 2 },
        { number_of_claimants: 1, veteran_file_number: "604969679", docket_type: dr, request_issue_count: 1 }
      ].each do |params|
        FactoryBot.create(
          :appeal,
          :assigned_to_judge,
          number_of_claimants: params[:number_of_claimants],
          active_task_assigned_at: Time.zone.now,
          veteran_file_number: params[:veteran_file_number],
          docket_type: params[:docket_type],
          closest_regional_office: "RO17",
          request_issues: FactoryBot.create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end
      # Create AMA tasks ready for distribution
      (1..30).each do |num|
        vet_file_number = format("3213213%02d", num)
        FactoryBot.create(
          :appeal,
          :ready_for_distribution,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          veteran_file_number: vet_file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          request_issues: FactoryBot.create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      LegacyAppeal.create(vacols_id: "2096907", vbms_id: "228081153S")
      LegacyAppeal.create(vacols_id: "2226048", vbms_id: "213912991S")
      LegacyAppeal.create(vacols_id: "2249056", vbms_id: "608428712S")
      LegacyAppeal.create(vacols_id: "2306397", vbms_id: "779309925S")
      LegacyAppeal.create(vacols_id: "2657227", vbms_id: "169397130S")
    end

    def create_tasks
      create_ama_distribution_tasks
      create_bva_dispatch_user_with_tasks
      create_qr_tasks
      create_different_hearings_tasks
      create_change_hearing_disposition_task
      create_ama_tasks
      create_board_grant_tasks
      create_veteran_record_request_tasks
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

    def create_root_task(appeal)
      FactoryBot.create(:root_task, appeal: appeal)
    end
  
    def create_task_at_judge_assignment(appeal, judge, assigned_at = Time.zone.yesterday)
      FactoryBot.create(:ama_judge_task,
                        assigned_to: judge,
                        assigned_at: assigned_at,
                        appeal: appeal,
                        parent: create_root_task(appeal))
    end
  
    def create_task_at_judge_review(appeal, judge, attorney)
      parent = FactoryBot.create(:ama_judge_decision_review_task,
                                 :in_progress,
                                 assigned_to: judge,
                                 appeal: appeal,
                                 parent: create_root_task(appeal))
      child = FactoryBot.create(
        :ama_attorney_task,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )
      child.update(status: :completed)
      FactoryBot.create(:attorney_case_review, task_id: child.id)
    end
  
    def create_task_at_colocated(appeal, judge, attorney, trait = ColocatedTask.actions_assigned_to_colocated.sample.to_sym)
      parent = FactoryBot.create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: create_root_task(appeal)
      )
  
      atty_task = FactoryBot.create(
        :ama_attorney_task,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )
  
      org_task_args = { appeal: appeal,
                        parent: atty_task,
                        assigned_by: attorney }
      FactoryBot.create(:ama_colocated_task, trait, org_task_args)
    end
  
    def create_colocated_legacy_tasks(attorney)
      [
        { vacols_id: "2096907", trait: :schedule_hearing },
        { vacols_id: "2226048", trait: :translation },
        { vacols_id: "2249056", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym },
        { vacols_id: "2306397", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym },
        { vacols_id: "2657227", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym }
      ].each do |attrs|
        org_task_args = { appeal: LegacyAppeal.find_by(vacols_id: attrs[:vacols_id]),
                          assigned_by: attorney }
        FactoryBot.create(:colocated_task, attrs[:trait], org_task_args)
      end
    end
  
    def create_task_at_attorney_review(appeal, judge, attorney)
      parent = FactoryBot.create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: create_root_task(appeal)
      )
  
      FactoryBot.create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )
    end
  
    def create_ama_tasks
      attorney = User.find_by(css_id: "BVASCASPER1")
      judge = User.find_by(css_id: "BVAAABSHIRE")
  
      # At Judge Assignment
      # evidence submission docket
      create_task_at_judge_assignment(@ama_appeals[0], judge, 35.days.ago)
      create_task_at_judge_assignment(@ama_appeals[1], judge)
  
      create_task_at_judge_review(@ama_appeals[2], judge, attorney)
      create_task_at_judge_review(@ama_appeals[3], judge, attorney)
      create_task_at_colocated(@ama_appeals[4], judge, attorney)
      create_task_at_colocated(FactoryBot.create(:appeal), judge, attorney, :translation)
      create_task_at_attorney_review(@ama_appeals[5], judge, attorney)
      create_task_at_attorney_review(@ama_appeals[6], judge, attorney)
      create_task_at_judge_assignment(@ama_appeals[7], judge)
      create_task_at_judge_review(@ama_appeals[8], judge, attorney)
      create_task_at_colocated(@ama_appeals[9], judge, attorney)
  
      9.times do
        create_appeal_at_judge_assignment(judge: judge, assigned_at: Time.zone.today)
      end
  
      create_colocated_legacy_tasks(attorney)
  
      5.times do
        FactoryBot.create(
          :ama_task,
          assigned_by: judge,
          assigned_to: Translation.singleton,
          parent: FactoryBot.create(:root_task)
        )
      end
  
      3.times do
        FactoryBot.create(
          :ama_judge_task,
          :in_progress,
          assigned_to: User.find_by(css_id: "BVAEBECKER"),
          appeal: FactoryBot.create(:appeal)
        )
      end
  
      FactoryBot.create_list(
        :appeal,
        8,
        :with_post_intake_tasks,
        docket_type: Constants.AMA_DOCKETS.direct_review
      )
  
      create_tasks_at_acting_judge
    end
  
    def create_tasks_at_acting_judge
      attorney = User.find_by(css_id: "BVASCASPER1")
      judge = User.find_by(css_id: "BVAAABSHIRE")
  
      acting_judge = FactoryBot.create(:user, css_id: "BVAACTING", station_id: 101, full_name: "Kris ActingVLJ_AVLJ Merle")
      FactoryBot.create(:staff, :attorney_judge_role, user: acting_judge)
  
      JudgeTeam.create_for_judge(acting_judge)
      JudgeTeam.for_judge(judge).add_user(acting_judge)
  
      create_appeal_at_judge_assignment(judge: acting_judge)
      create_task_at_attorney_review(FactoryBot.create(:appeal), judge, acting_judge)
      create_task_at_attorney_review(FactoryBot.create(:appeal), acting_judge, attorney)
      create_task_at_judge_review(FactoryBot.create(:appeal), judge, acting_judge)
      create_task_at_judge_review(FactoryBot.create(:appeal), acting_judge, attorney)
  
      # Create Acting Judge Legacy Appeals
      create_legacy_appeal_at_acting_judge
    end
  
    def create_legacy_appeal_at_acting_judge
      # Find the 2 VACOLS Cases for the Acting Judge (seeded from local/vacols/VACOLS::Case_dump.csv)
      # - Case 3662860 does not have a decision drafted for it yet, so it is assigned to the AVLJ as an attorney
      # - Case 3662859 has a valid decision document, so it is assigned to the AVLJ as a judge
      vacols_case_attorney = VACOLS::Case.find_by(bfkey: "3662860")
      vacols_case_judge = VACOLS::Case.find_by(bfkey: "3662859")
  
      # Initialize the attorney and judge case issue list
      attorney_case_issues = []
      judge_case_issues = []
      %w[5240 5241 5242 5243 5250].each do |lev2|
        # Assign every other case issue to attorney
        case_issues = lev2.to_i.even? ? attorney_case_issues : judge_case_issues
  
        # Create issue and push into the case issues list
        case_issues << FactoryBot.create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: lev2)
      end
  
      # Update the Case with the Issues
      vacols_case_attorney.update!(case_issues: attorney_case_issues)
      vacols_case_judge.update!(case_issues: judge_case_issues)
  
      # Create the Judge and Attorney Legacy Appeals
      [vacols_case_attorney, vacols_case_judge].each do |vacols_case|
        # Assign the Vacols Case to the new Legacy Appeal
        FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
      end
    end
  
    def create_board_grant_tasks
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective May 1 2011"
      notes = "Pain disorder with 80\% evaluation per examination"
  
      3.times do |index|
        board_grant_task = FactoryBot.create(:board_grant_effectuation_task,
                                             status: "assigned",
                                             assigned_to: nca)
  
        request_issues = FactoryBot.create_list(:request_issue, 3,
                                                :nonrating,
                                                contested_issue_description: "#{index} #{description}",
                                                notes: "#{index} #{notes}",
                                                benefit_type: nca.url,
                                                decision_review: board_grant_task.appeal)
  
        request_issues.each do |request_issue|
          # create matching decision issue
          FactoryBot.create(
            :decision_issue,
            :nonrating,
            disposition: "allowed",
            decision_review: board_grant_task.appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 2.months.ago,
            benefit_type: request_issue.benefit_type
          )
        end
      end
    end
  
    def create_veteran_record_request_tasks
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
  
      3.times do |_index|
        FactoryBot.create(:veteran_record_request_task,
                          status: "assigned",
                          assigned_to: nca)
      end
    end

    def create_appeal_at_judge_assignment(judge: User.find_by_css_id("BVAAABSHIRE"), assigned_at: Time.zone.now)
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"
  
      FactoryBot.create(
        :appeal,
        :assigned_to_judge,
        number_of_claimants: 1,
        associated_judge: judge,
        active_task_assigned_at: assigned_at,
        veteran_file_number: Generators::Random.unique_ssn,
        docket_type: Constants.AMA_DOCKETS.direct_review,
        closest_regional_office: "RO17",
        request_issues: FactoryBot.create_list(
          :request_issue, 2, :rating, contested_issue_description: description, notes: notes
        )
      )
    end

    # these really belong in Seeds::Intake but we put them here for now because they rely on Seeds::Facols
    def create_legacy_issues_eligible_for_opt_in
      # this vet number exists in local/vacols VBMS and BGS setup csv files.
      veteran_file_number_legacy_opt_in = "872958715S"
      legacy_vacols_id = "LEGACYID"
  
      # always delete and start fresh
      VACOLS::Case.where(bfkey: legacy_vacols_id).delete_all
      VACOLS::CaseIssue.where(isskey: legacy_vacols_id).delete_all
  
      case_issues = []
      %w[5240 5241 5242 5243 5250].each do |lev2|
        case_issues << FactoryBot.create(:case_issue,
                                         issprog: "02",
                                         isscode: "15",
                                         isslev1: "04",
                                         isslev2: lev2)
      end
      correspondent = VACOLS::Correspondent.find_or_create_by(stafkey: 100)
      folder = VACOLS::Folder.find_or_create_by(ticknum: legacy_vacols_id, tinum: 1)
      vacols_case = FactoryBot.create(:case_with_soc,
                                      :status_advance,
                                      case_issues: case_issues,
                                      correspondent: correspondent,
                                      folder: folder,
                                      bfkey: legacy_vacols_id,
                                      bfcorlid: veteran_file_number_legacy_opt_in)
      FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
    end
  end
end
