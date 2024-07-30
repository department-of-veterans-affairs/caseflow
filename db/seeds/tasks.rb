# frozen_string_literal: true

# create tasks and their related appeals
# to do: split this up more logically for legacy, AMA, etc.
module Seeds
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Lint/DuplicateMethods
  class Tasks < Base
    def initialize
      @ama_appeals = []
      initial_file_number_and_participant_id
    end

    def seed!
      create_ama_appeals
      create_tasks
      create_legacy_issues_eligible_for_opt_in # to do: move to Seeds::Intake
      create_attorney_case_review_for_legacy_appeals
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 100_000_000
      @participant_id ||= 500_000_000
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

    def create_ama_appeals
      notes = "Pain disorder with 100\% evaluation per examination"

      create(
        :appeal,
        claimants: [
          build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO"),
          build(:claimant, participant_id: "OTHER_CLAIMANT")
        ],
        docket_type: Constants.AMA_DOCKETS.direct_review,
        request_issues: create_list(:request_issue, 3, :nonrating, notes: notes)
      )

      es = Constants.AMA_DOCKETS.evidence_submission
      dr = Constants.AMA_DOCKETS.direct_review
      # Older style, tasks to be created later
      [
        { number_of_claimants: nil, docket_type: es, request_issue_count: 3 },
        { number_of_claimants: 1, docket_type: es, request_issue_count: 1 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 3 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 5 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 8 }
      ].each do |params|
        @ama_appeals << create(
          :appeal,
          number_of_claimants: params[:number_of_claimants],
          docket_type: params[:docket_type],
          request_issues: create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end

      # Newer style, tasks created through the Factory trait
      [
        { number_of_claimants: nil, docket_type: dr, request_issue_count: 2 },
        { number_of_claimants: 1, docket_type: dr, request_issue_count: 1 }
      ].each do |params|
        create(
          :appeal,
          :assigned_to_judge,
          number_of_claimants: params[:number_of_claimants],
          active_task_assigned_at: Time.zone.now,
          docket_type: params[:docket_type],
          closest_regional_office: "RO17",
          request_issues: create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals ready for distribution received this month
      (1..30).each do |num|
        create(
          :appeal,
          :ready_for_distribution,
          veteran: create_veteran,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          receipt_date: num.days.ago,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals ready for distribution received over a year ago
      (1..5).each do |num|
        create(
          :appeal,
          :ready_for_distribution,
          veteran: create_veteran,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          receipt_date: (365 + num).days.ago,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals ready for distribution received over 65 days ago
      (1..5).each do |num|
        create(
          :appeal,
          :ready_for_distribution,
          veteran: create_veteran,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          receipt_date: (65 + num).days.ago,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals ready for distribution in the future
      (1..5).each do |num|
        create(
          :appeal,
          :ready_for_distribution,
          veteran: create_veteran,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          receipt_date: num.days.from_now,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals blocked for distribution due to Evidence Window received this month
      (1..30).each do |num|
        create(
          :appeal,
          :with_post_intake_tasks,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.evidence_submission,
          closest_regional_office: "RO17",
          receipt_date: num.days.ago,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end

      # Create AMA appeals blocked for distribution due to blocking mail received this month
      (1..30).each do |num|
        create(
          :appeal,
          :mail_blocking_distribution,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          receipt_date: num.days.ago,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end
      LegacyAppeal.find_or_create_by(vacols_id: "2096907", vbms_id: "228081153S")
      LegacyAppeal.find_or_create_by(vacols_id: "2226048", vbms_id: "213912991S")
      LegacyAppeal.find_or_create_by(vacols_id: "2249056", vbms_id: "608428712S")
      LegacyAppeal.find_or_create_by(vacols_id: "2306397", vbms_id: "779309925S")
      LegacyAppeal.find_or_create_by(vacols_id: "2657227", vbms_id: "169397130S")
    end

    def create_tasks
      create_ama_distribution_tasks
      create_bva_dispatch_user_with_tasks
      create_bva_dispatch_user_for_split_appeals
      create_qr_tasks
      create_different_hearings_tasks
      create_legacy_hearing_tasks
      create_change_hearing_disposition_task
      create_ama_tasks
      create_board_grant_tasks
      create_veteran_record_request_tasks
    end

    def create_ama_distribution_tasks
      veteran = create_veteran(first_name: "Julius", last_name: "Hodge")
      appeal = create(:appeal, veteran: veteran, docket_type: Constants.AMA_DOCKETS.evidence_submission)
      create(
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
      BvaDispatch.singleton.add_user(User.find_or_create_by(css_id: "BVAGWHITE", station_id: "101"))

      [42, 66, 13].each do |rand_seed|
        create_task_at_bva_dispatch(rand_seed)
      end
    end

    def create_task_at_bva_dispatch(seed = Faker::Number.number(digits: 3))
      Faker::Config.random = Random.new(seed)
      vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)

      notes = "Pain disorder with 100\% evaluation per examination"
      notes += ". Created with the inital_tasks factory trait and moved thru"

      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 1, :nonrating, notes: notes
        )
      )

      root_task = appeal.root_task
      judge = User.find_by_css_id("BVAAWAKEFIELD")
      judge_task = create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: root_task
      )

      atty = User.find_by_css_id("BVAABELANGER")
      atty_task = create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: atty,
        assigned_by: judge,
        parent: judge_task,
        appeal: appeal
      )

      appeal.request_issues.each do |request_issue|
        create(
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

      # appeals at dispatch
      5.times do
        notes = "Pain disorder with 100\% evaluation per examination"
        notes += ". Created with the at_bva_dispatch factory trait"

        vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)

        attorney = User.find_by_css_id("BVASCASPER1")
        judge = User.find_by_css_id("BVAAABSHIRE")

        appeal = create(
          :appeal,
          :at_bva_dispatch,
          number_of_claimants: 1,
          veteran_file_number: vet.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          associated_judge: judge,
          associated_attorney: attorney,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )

        appeal.request_issues.each do |request_issue|
          create(
            :decision_issue,
            :nonrating,
            disposition: "allowed",
            decision_review: appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 2.months.ago,
            benefit_type: request_issue.benefit_type
          )
        end
      end

      # dispatched appeals
      10.times do
        notes = "Pain disorder with 100\% evaluation per examination"
        notes += ". Created with the dispatched factory trait"

        vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)

        attorney = User.find_by_css_id("BVASCASPER1")
        judge = User.find_by_css_id("BVAAABSHIRE")

        appeal = create(
          :appeal,
          :dispatched,
          number_of_claimants: 1,
          veteran_file_number: vet.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          associated_judge: judge,
          associated_attorney: attorney,
          request_issues: create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )

        appeal.request_issues.each do |request_issue|
          create(
            :decision_issue,
            :nonrating,
            disposition: "allowed",
            decision_review: appeal,
            request_issues: [request_issue],
            rating_promulgation_date: 2.months.ago,
            benefit_type: request_issue.benefit_type
          )
        end
      end
    end

    def create_bva_dispatch_user_for_split_appeals
      BvaDispatch.singleton.add_user(User.find_or_create_by(css_id: "BVAGBLACK", station_id: "101"))

      (1..30).each do |rand_seed|
        create_task_at_bva_dispatch_for_split_appeals(rand_seed)
      end
    end

    def create_task_at_bva_dispatch_for_split_appeals(seed = Faker::Number.number(digits: 3))
      Faker::Config.random = Random.new(seed)

      vet_file_number = format("1415926%<num>02d", num: seed)
      vet = create(
        :veteran,
        file_number: vet_file_number,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )

      notes = "Pain disorder with 100\% evaluation per examination"
      notes += ". Created with the initial_tasks factory trait and moved thru"

      # Create appeal with numerous request
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 4, :nonrating, notes: notes
        )
      )

      root_task = appeal.root_task
      judge = User.find_by_css_id("BVAAWAKEFIELD")
      judge_task = create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: root_task
      )

      atty = User.find_by_css_id("BVAABELANGER")
      atty_task = create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: atty,
        assigned_by: judge,
        parent: judge_task,
        appeal: appeal
      )

      appeal.request_issues.each do |request_issue|
        create(
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
      appeal.tasks.where(type: "BvaDispatchTask").map(&:completed!)
    end

    def create_task_at_quality_review
      # created Code Climate issue for unused variable.
      # judge_name = "Madhu Judge_CaseAtQR Burnham", attorney_name = "Bailey Attorney_CaseAtQR Eoin"
      vet = create(
        :veteran,
        file_number: vet_file_number,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name
      )

      notes = "Pain disorder with 100\% evaluation per examination"
      notes += ". Created with the initial_tasks factory trait and moved thru"

      # Create appeal with numerous request
      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 4, :nonrating, notes: notes
        )
      )

      root_task = appeal.root_task
      judge = User.find_by_css_id("BVAAWAKEFIELD")
      judge_task = create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: root_task
      )

      atty = User.find_by_css_id("BVAABELANGER")
      atty_task = create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: atty,
        assigned_by: judge,
        parent: judge_task,
        appeal: appeal
      )

      appeal.request_issues.each do |request_issue|
        create(
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
      appeal.tasks.where(type: "BvaDispatchTask").map(&:completed!)
    end

    def create_task_at_quality_review(
      judge_name = "Madhu Judge_CaseAtQR Burnham", attorney_name = "Bailey Attorney_CaseAtQR Eoin"
    )
      vet = create_veteran(first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      notes = "Pain disorder with 100\% evaluation per examination"

      appeal = create(
        :appeal,
        :with_post_intake_tasks,
        number_of_claimants: 1,
        veteran_file_number: vet.file_number,
        docket_type: Constants.AMA_DOCKETS.direct_review,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 1, :nonrating, notes: notes
        )
      )
      root_task = appeal.root_task
      distribution_task = appeal.tasks.find_by(type: "DistributionTask")

      judge = User.find_by(full_name: judge_name) || create(:user, station_id: 101, full_name: judge_name)
      create(:staff, :judge_role, user: judge)
      judge_task = JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge)

      atty = User.find_by(full_name: attorney_name) || create(:user, station_id: 101, full_name: attorney_name)
      create(:staff, :attorney_role, user: atty)
      atty_task_params = { appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }
      atty_task = AttorneyTask.create!(atty_task_params)

      atty_task.update!(status: Constants.TASK_STATUSES.completed)
      judge_task.update!(status: Constants.TASK_STATUSES.completed)
      distribution_task.update!(status: Constants.TASK_STATUSES.completed)

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

    def create_legacy_hearing_tasks
      # Phoenix and St. Petersburg get legacy hearing requests ("Legacy Veterans Waiting" tab)
      %w[RO17 RO45].each do |regional_office|
        create_legacy_appeals_with_open_schedule_hearing_task(regional_office, 30)
      end
    end

    def create_different_hearings_tasks
      (%w[RO17 RO19 RO31 RO43 RO45] + [nil]).each do |regional_office|
        30.times do |num|
          appeal = create(
            :appeal,
            :with_request_issues,
            :hearing_docket,
            veteran_is_not_claimant: Faker::Boolean.boolean,
            stream_type: Constants.AMA_STREAM_TYPES.original,
            receipt_date: num.days.ago,
            claimants: [
              create(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO_#{rand(10**10)}")
            ],
            closest_regional_office: regional_office
          )

          create(:available_hearing_locations, regional_office, appeal: appeal)

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

          schedule_hearing_task_status = [:completed, :in_progress].sample

          create(
            :schedule_hearing_task,
            schedule_hearing_task_status,
            parent: parent_hearing_task,
            appeal: appeal
          )

          # For completed hearing tasks, generate additional tasks too.
          next unless schedule_hearing_task_status == :completed

          disposition_task = create(
            :assign_hearing_disposition_task,
            parent: parent_hearing_task,
            appeal: appeal
          )
          create(
            [:no_show_hearing_task, :evidence_submission_window_task].sample,
            parent: disposition_task,
            appeal: appeal
          )
        end
      end
    end

    def create_change_hearing_disposition_task
      hearings_member = User.find_or_create_by(css_id: "BVATWARNER", station_id: 101)
      hearing_day = create(:hearing_day, created_by: hearings_member, updated_by: hearings_member)
      veteran = create_veteran(first_name: "Abellona", last_name: "Valtas")
      appeal = create(:appeal, :hearing_docket, veteran_file_number: veteran.file_number)
      root_task = create(:root_task, appeal: appeal)
      distribution_task = create(:distribution_task, parent: root_task)
      parent_hearing_task = create(:hearing_task, parent: distribution_task)
      create(:assign_hearing_disposition_task, parent: parent_hearing_task)

      hearing = create(
        :hearing,
        appeal: appeal,
        hearing_day: hearing_day,
        created_by: hearings_member,
        updated_by: hearings_member
      )
      create(:hearing_task_association, hearing: hearing, hearing_task: parent_hearing_task)
      create(:change_hearing_disposition_task, parent: parent_hearing_task)
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

      legacy_appeal = LegacyAppeal.find_or_create_by_vacols_id(vacols_id) if vacols_id.present?
      legacy_appeal.update!(closest_regional_office: ro_key)
      legacy_appeal
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Could not load FACOLS record for vacols_id #{vacols_id} -- are FACOLS seeds present?")
    end

    def create_root_task(appeal)
      create(:root_task, appeal: appeal)
    end

    def create_task_at_judge_assignment(appeal, judge, assigned_at = Time.zone.yesterday)
      create(:ama_judge_assign_task,
             assigned_to: judge,
             assigned_at: assigned_at,
             appeal: appeal,
             parent: create_root_task(appeal))
    end

    def create_task_at_judge_review(appeal, judge, attorney)
      parent = create(:ama_judge_decision_review_task,
                      :in_progress,
                      assigned_to: judge,
                      appeal: appeal,
                      parent: create_root_task(appeal))
      child = create(
        :ama_attorney_task,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )
      child.update(status: :completed)
      create(:attorney_case_review, task_id: child.id)
    end

    def create_task_at_colocated(
      appeal, judge, attorney, trait = ColocatedTask.actions_assigned_to_colocated.sample.to_sym
    )
      parent = create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: create_root_task(appeal)
      )

      atty_task = create(
        :ama_attorney_task,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )

      org_task_args = { appeal: appeal,
                        parent: atty_task,
                        assigned_by: attorney }
      create(:ama_colocated_task, trait, org_task_args)
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
        # do not attempt to create a new colocated task if one already exists for the this LegacyAppeal
        next if org_task_args[:appeal].tasks.map { |task| task.is_a?(ColocatedTask) }.any? { |bool| bool }

        create(:colocated_task, attrs[:trait], org_task_args)
      end
    end

    def create_task_at_attorney_review(appeal, judge, attorney)
      parent = create(
        :ama_judge_decision_review_task,
        assigned_to: judge,
        appeal: appeal,
        parent: create_root_task(appeal)
      )

      create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent,
        appeal: appeal
      )
    end

    def create_ama_tasks
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")

      # At Judge Assignment
      # evidence submission docket
      create_task_at_judge_assignment(@ama_appeals[0], judge, 35.days.ago)
      create_task_at_judge_assignment(@ama_appeals[1], judge)

      create_task_at_judge_review(@ama_appeals[2], judge, attorney)
      create_task_at_judge_review(@ama_appeals[3], judge, attorney)
      create_task_at_colocated(@ama_appeals[4], judge, attorney)
      create_task_at_colocated(create(:appeal), judge, attorney, :translation)
      create_task_at_attorney_review(@ama_appeals[5], judge, attorney)
      create_task_at_attorney_review(@ama_appeals[6], judge, attorney)
      create_task_at_judge_assignment(@ama_appeals[7], judge)
      create_task_at_judge_review(@ama_appeals[8], judge, attorney)
      create_task_at_colocated(@ama_appeals[9], judge, attorney)

      5.times do
        create_task_at_colocated(create(:appeal), judge, attorney, :schedule_hearing)
      end

      9.times do
        create_appeal_at_judge_assignment(judge: judge, assigned_at: Time.zone.today)
      end

      create_colocated_legacy_tasks(attorney)

      5.times do
        create(
          :ama_task,
          assigned_by: judge,
          assigned_to: Translation.singleton,
          parent: create(:root_task)
        )
      end

      3.times do
        create(
          :ama_judge_assign_task,
          :in_progress,
          assigned_to: User.find_by_css_id("BVAEBECKER"),
          appeal: create(:appeal)
        )
      end

      8.times do
        create(
          :appeal,
          :with_post_intake_tasks,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          veteran: create_veteran
        )
      end

      create_tasks_at_acting_judge
    end

    def create_tasks_at_acting_judge
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")
      acting_judge = User.find_by_css_id("BVAACTING")

      if !acting_judge
        acting_judge = create(:user, css_id: "BVAACTING", station_id: 101, full_name: "Kris ActingVLJ_AVLJ Merle")
        create(:staff, :attorney_judge_role, user: acting_judge)
      end

      JudgeTeam.create_for_judge(acting_judge) unless JudgeTeam.for_judge(acting_judge)
      JudgeTeam.for_judge(judge).add_user(acting_judge)

      create_appeal_at_judge_assignment(judge: acting_judge)
      create_task_at_attorney_review(create(:appeal), judge, acting_judge)
      create_task_at_attorney_review(create(:appeal), acting_judge, attorney)
      create_task_at_judge_review(create(:appeal), judge, acting_judge)
      create_task_at_judge_review(create(:appeal), acting_judge, attorney)

      # Create Acting Judge Legacy Appeals
      create_legacy_appeal_at_acting_judge
    end

    def create_legacy_appeal_at_acting_judge
      # Find the 2 VACOLS Cases for the Acting Judge (seeded from local/vacols/VACOLS::Case_dump.csv)
      # - Case 3662860 does not have a decision drafted for it yet, so it is assigned to the AVLJ as an attorney
      # - Case 3662859 has a valid decision document, so it is assigned to the AVLJ as a judge
      vacols_case_attorney = VACOLS::Case.find_by(bfkey: "3662860")
      vacols_case_judge = VACOLS::Case.find_by(bfkey: "3662859")

      return if LegacyAppeal.find_by(vacols_id: vacols_case_attorney.bfkey) ||
                LegacyAppeal.find_by(vacols_id: vacols_case_judge.bfkey)

      # Initialize the attorney and judge case issue list
      attorney_case_issues = []
      judge_case_issues = []
      %w[5240 5241 5242 5243 5250].each do |level|
        # Assign every other case issue to attorney
        case_issues = level.to_i.even? ? attorney_case_issues : judge_case_issues

        # Create issue and push into the case issues list
        case_issues << create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: level)
      end

      # Update the Case with the Issues
      vacols_case_attorney.update!(case_issues: attorney_case_issues)
      vacols_case_judge.update!(case_issues: judge_case_issues)

      # Create the Judge and Attorney Legacy Appeals
      [vacols_case_attorney, vacols_case_judge].each do |vacols_case|
        # Assign the Vacols Case to the new Legacy Appeal
        create(:legacy_appeal, vacols_case: vacols_case)
      end
    end

    def create_board_grant_tasks
      nca = BusinessLine.find_by(name: "National Cemetery Administration")
      description = "Service connection for pain disorder is granted with an evaluation of 50\% effective May 1 2011"
      notes = "Pain disorder with 80\% evaluation per examination"

      3.times do |index|
        board_grant_task = create(:board_grant_effectuation_task,
                                  status: "assigned",
                                  assigned_to: nca)

        request_issues = create_list(:request_issue, 3,
                                     :nonrating,
                                     contested_issue_description: "#{index} #{description}",
                                     notes: "#{index} #{notes}",
                                     benefit_type: nca.url,
                                     decision_review: board_grant_task.appeal)

        request_issues.each do |request_issue|
          # create matching decision issue
          create(
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
        create(:veteran_record_request_task,
               status: "assigned",
               assigned_to: nca)
      end
    end

    def create_appeal_at_judge_assignment(judge: User.find_by_css_id("BVAAABSHIRE"), assigned_at: Time.zone.now)
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"

      create(
        :appeal,
        :assigned_to_judge,
        veteran: create_veteran,
        number_of_claimants: 1,
        associated_judge: judge,
        active_task_assigned_at: assigned_at,
        docket_type: Constants.AMA_DOCKETS.direct_review,
        closest_regional_office: "RO17",
        request_issues: create_list(
          :request_issue, 2, :rating, contested_issue_description: description, notes: notes
        )
      )
    end

    # these really belong in Seeds::Intake but we put them here for now because they rely on Seeds::Facols
    def create_legacy_issues_eligible_for_opt_in
      # this vet number exists in local/vacols VBMS and BGS setup csv files.
      veteran_file_number_legacy_opt_in = "872958715S"
      legacy_vacols_id = "LEGACYID"

      return if LegacyAppeal.find_by(vacols_id: legacy_vacols_id)

      # always delete and start fresh
      VACOLS::Case.where(bfkey: legacy_vacols_id).delete_all
      VACOLS::CaseIssue.where(isskey: legacy_vacols_id).delete_all

      case_issues = []
      %w[5240 5241 5242 5243 5250].each do |level|
        case_issues << create(:case_issue,
                              issprog: "02",
                              isscode: "15",
                              isslev1: "04",
                              isslev2: level)
      end
      correspondent = VACOLS::Correspondent.find_or_create_by(stafkey: 100)
      folder = VACOLS::Folder.find_or_create_by(ticknum: legacy_vacols_id, tinum: 1)
      vacols_case = create(:case_with_soc,
                           :status_advance,
                           :type_original,
                           case_issues: case_issues,
                           correspondent: correspondent,
                           folder: folder,
                           bfkey: legacy_vacols_id,
                           bfcorlid: veteran_file_number_legacy_opt_in)
      create(:legacy_appeal, vacols_case: vacols_case)
    end

    # This whole section probably belongs in Seeds::Hearings, but since it doesn't actually create
    # a hearing I'm leaving it here for now
    def create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      create(
        :case,
        :video_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder
      )
    end

    def create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      create(
        :case,
        :travel_board_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder
      )
    end

    def create_vacols_entries(vacols_titrnum, docket_number, regional_office, type)
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

      # Create the vacols_case
      begin
        retries ||= 0
        if type == "video"
          vacols_case = create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
        end
        if type == "travel"
          vacols_case = create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
        end
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the legacy_appeal, this doesn't fail with index problems, so no need to retry
      legacy_appeal = create(
        :legacy_appeal,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )
      create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      # Return the legacy_appeal
      legacy_appeal
    end

    def create_open_schedule_hearing_task_for_legacy(legacy_appeal, user)
      root_task = create(:root_task, appeal: legacy_appeal)
      distribution_task = create(
        :distribution_task,
        appeal: legacy_appeal,
        parent: root_task
      )
      parent_hearing_task = create(
        :hearing_task,
        assigned_by: user,
        assigned_to: user,
        parent: distribution_task,
        appeal: legacy_appeal
      )
      create(
        :schedule_hearing_task,
        :in_progress,
        assigned_to: user,
        assigned_by: user,
        parent: parent_hearing_task,
        appeal: legacy_appeal
      )
    end

    def create_legacy_appeals_with_open_schedule_hearing_task(regional_office, number_of_appeals_to_create)
      # The offset should start at 100 to avoid collisions
      offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a
      # Use a hearings user so the factories don't try to create one (and sometimes fail)
      user = User.find_by_css_id("BVASYELLOW")
      # Set this for papertrail when creating vacols_case
      RequestStore[:current_user] = user

      offsets.each do |offset|
        docket_number = "180000#{offset}"
        next unless VACOLS::Folder.find_by(tinum: docket_number).nil?

        # Create the veteran for this legacy appeal
        veteran = create_veteran

        vacols_titrnum = veteran.file_number

        # Create some video and some travel hearings
        type = offset.even? ? "travel" : "video"

        # Create the folder, case, and appeal, there's a lot of retry logic in here
        # because the way FactoryBot sequences work isn't quite right for this case
        legacy_appeal = create_vacols_entries(vacols_titrnum, docket_number, regional_office, type)
        # Create the task tree, need to create each task like this to avoid user creation and index conflicts
        create_open_schedule_hearing_task_for_legacy(legacy_appeal, user)
      end

      # Once everything is created, refresh the cache or they won't appear in the UI
      UpdateCachedAppealsAttributesJob.new.cache_legacy_appeals
    end

    # TODO: This seed method is only creating an attorney_case_review for the first
    # LegacyAppeal in that satisfies the condition investigate why this is happening
    # and fix it.
    def create_attorney_case_review_for_legacy_appeals
      judge = User.find_by_css_id("BVAAABSHIRE")
      attorney = User.find_by_css_id("BVASCASPER1")

      LegacyAppeal.all.each do |la|
        created_at = la.vacols_case_review&.created_at

        next unless la.location_code == judge.vacols_uniq_id && created_at.present?

        task_id = "#{la.vacols_id}-#{VacolsHelper.day_only_str(created_at)}"

        create(
          :attorney_case_review,
          appeal: la,
          reviewing_judge: judge,
          attorney: attorney,
          task_id: task_id,
          note: Faker::Lorem.sentence
        )
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Lint/DuplicateMethods
end
