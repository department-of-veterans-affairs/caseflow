# frozen_string_literal: true

# Veterans Health Administration related seeds

module Seeds
  class VhaChangeHistory < Base
    PROGRAM_OFFICES = [
      "Community Care - Payment Operations Management",
      "Community Care - Veteran and Family Members Program",
      "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel",
      "Prosthetics"
    ].freeze

    CLAIMANT_TYPES = [
      :veteran_claimant,
      :dependent_claimant,
      :attorney_claimant,
      :healthcare_claimant,
      :other_claimant
    ].freeze

    BENEFIT_TYPE_LIST = Constants::BENEFIT_TYPES.keys.map(&:to_s).freeze

    DISPOSITION_LIST = ["Granted", "Denied", "DTA Error", "Dismissed", "Withdrawn"].freeze

    def seed!
      RequestStore[:current_user] = User.system_user
      Timecop.freeze(rand(5..15).days.ago) do
        create_seeds_for_change_history
      end
    end

    private

    def create_seeds_for_change_history
      Constants::ISSUE_CATEGORIES["vha"].each do |issue_type|
        CLAIMANT_TYPES.each do |claimant_type|
          create_hlr_seed(claimant_type, issue_type)
          create_sc_seeds(claimant_type, issue_type)
        end
      end
      create_hlr_seeds_for_change_history
      create_sc_seeds_for_change_history
    end

    def create_hlr_seeds_for_change_history
      15.times do
        create_hlr_without_decision_date
        create_hlr_with_decision_date
        create_hlr_with_disposition
        create_hlr_with_unidentified_issue
        create_cancelled_hlr
        create_withdrawn_hlr
        create_hlr_with_unidentified_issue_without_decision_date
      end
    end

    def create_sc_seeds_for_change_history
      15.times do
        create_sc_without_decision_date
        create_sc_with_decision_date
        create_sc_with_unidentified_issue
        create_sc_with_unidentified_issue_without_decision_date
        create_sc_with_disposition
        create_withdrawn_sc
        create_cancelled_sc
      end
    end

    def create_hlr_seed(*args)
      claimant_type, issue_type = args
      PaperTrail.request(enabled: false) do
        create(:higher_level_review,
               :with_intake,
               :with_issue_type,
               :processed,
               :update_assigned_at,
               assigned_at: rand(1.year.ago..10.minutes.ago),
               benefit_type: "vha",
               decision_date: 4.months.ago,
               claimant_type: claimant_type,
               issue_type: issue_type,
               description: "seeded HLR in progress",
               number_of_claimants: 1)
      end
    end

    def create_sc_seeds(*args)
      claimant_type, issue_type = args
      PaperTrail.request(enabled: false) do
        create(:supplemental_claim,
               :with_intake,
               :with_issue_type,
               :processed,
               :update_assigned_at,
               assigned_at: rand(1.year.ago..10.minutes.ago),
               benefit_type: "vha",
               decision_date: 4.months.ago,
               claimant_type: claimant_type,
               issue_type: issue_type,
               description: "seeded SC in progress",
               number_of_claimants: 1)
      end
    end

    # Inserts hlr with or with out decision date.
    # :reek:FeatureEnvy
    def create_hlr_with_decision_date
      # step 1: Insert decision review without decision date
      # this will be in incomplete tab at this moment.
      hlr = create(:higher_level_review,
                   :with_intake,
                   :without_decision_date,
                   :processed,
                   :update_assigned_at,
                   assigned_at: rand(1.year.ago..1.day.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   description: "with decision date added",
                   number_of_claimants: 1)

      # step 2: add decision date and change the status of task to assigned
      # this will move decision review to in progress tab.
      ri = hlr.request_issues.last
      Timecop.freeze(rand(17.days.ago..1.day.ago)) do
        create_request_issues_update(ri)
      end
      hlr
    end

    # :reek:FeatureEnvy
    def create_sc_with_decision_date
      # step 1: Insert decision review without decision date
      # this will be in incomplete tab at this moment.
      sc = create_sc_without_decision_date

      # step 2: add decision date and change the status of task to assigned
      # this will move decision review to in progress tab.
      ri = sc.request_issues.last
      Timecop.freeze(rand(17.days.ago..1.day.ago)) do
        create_request_issues_update(ri)
      end
      sc
    end

    # :reek:FeatureEnvy
    def create_hlr_without_decision_date
      # step 1: create decision review without decision date.
      # will be in-complete decision

      hlr = create(:higher_level_review,
                   :with_intake,
                   :without_decision_date,
                   :processed,
                   :update_assigned_at,
                   assigned_at: rand(1.year.ago..1.day.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   description: "with decision date added",
                   number_of_claimants: 1)
      hlr
    end

    # :reek:FeatureEnvy
    def create_sc_without_decision_date
      # step 1: create Supplemental claim without decision date.
      # will be in-complete decision

      sc = create(:supplemental_claim,
                  :with_intake,
                  :without_decision_date,
                  :processed,
                  :update_assigned_at,
                  assigned_at: rand(1.year.ago..1.day.ago),
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  description: "with decision date added",
                  number_of_claimants: 1)

      sc
    end

    # :reek:FeatureEnvy
    def create_withdrawn_hlr
      # step1: create decision review with decision date
      # it will be in-progress
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_issue_type,
                   benefit_type: "vha",
                   decision_date: rand(1.year.ago..1.day.ago),
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   description: "withdrawn case",
                   number_of_claimants: 1)

      hlr.create_business_line_tasks!
      ri = hlr.request_issues.last
      # step2. edit decision review and withdraw issue
      Timecop.freeze(ri.created_at + 1.day) do
        ri.withdraw!(Time.zone.now)
        create_request_issues_update_for_withdraw(ri)
        task = hlr.tasks.last
        task.status = "cancelled"
        task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
        task.save
      end
    end

    # :reek:FeatureEnvy
    def create_withdrawn_sc
      # step1: create decision review with decision date
      # it will be in-progress
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_issue_type,
                  benefit_type: "vha",
                  decision_date: rand(1.year.ago..1.day.ago),
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  description: "withdrawn case",
                  number_of_claimants: 1)

      sc.create_business_line_tasks!
      ri = sc.request_issues.last

      # step2. edit decision review and withdraw issue

      Timecop.freeze(ri.created_at + 1.day) do
        ri.withdraw!(Time.zone.now)
        create_request_issues_update_for_withdraw(ri)

        task = sc.tasks.last
        task.status = "cancelled"
        task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
        task.save
      end
    end

    # :reek:FeatureEnvy
    def create_cancelled_hlr
      # step 1: create decision request with decision date
      # in progress tab

      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_issue_type,
                   decision_date: rand(1.year.ago..1.day.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   description: "Cancelled task",
                   number_of_claimants: 1)

      hlr.create_business_line_tasks!
      ri = hlr.request_issues.last

      # step 2. remove the issue from the decision review, which should cancel the task

      Timecop.freeze(ri.updated_at + rand(1..3).days) do
        ri.remove!
        create_request_issues_update_for_cancel(ri)
        task = hlr.tasks.last
        task.status = "cancelled"
        task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
        task.save
      end
    end

    # :reek:FeatureEnvy
    def create_cancelled_sc
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_issue_type,
                  decision_date: rand(1.year.ago..1.day.ago),
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  description: "Cancelled task",
                  number_of_claimants: 1)

      sc.create_business_line_tasks!
      ri = sc.request_issues.last

      # step 2. remove the issue from the decision review, which should cancel the task

      Timecop.freeze(ri.updated_at + rand(1..3).days) do
        ri.remove!
        create_request_issues_update_for_cancel(ri)
        task = sc.tasks.last
        task.assigned_at = Time.zone.now
        task.status = "cancelled"
        task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
        task.save
      end
    end

    # adds hlr with random disposition.
    # :reek:FeatureEnvy
    def create_hlr_with_disposition
      hlr = create_hlr_with_decision_date

      # step 3: add disposition to the decision review and change status to complete.
      # will be in complete tab
      Timecop.freeze(hlr.updated_at + 1.day) do
        create(:decision_issue,
               benefit_type: "vha",
               request_issues: hlr.request_issues,
               decision_review: hlr,
               disposition: DISPOSITION_LIST.sample,
               caseflow_decision_date: Time.zone.now)

        task = hlr.tasks.last
        task.status = "completed"
        task.updated_at = Time.zone.now + 1.minute
        vha = VhaBusinessLine.singleton
        task.completed_by_id = vha.users.sample.id
        task.save!
      end
    end

    # :reek:FeatureEnvy
    def create_sc_with_disposition
      sc = create_sc_with_decision_date

      # step 3: add disposition to the decision review and change status to complete.
      # will be in complete tab
      Timecop.freeze(sc.updated_at + 1.day) do
        create(:decision_issue,
               benefit_type: "vha",
               request_issues: sc.request_issues,
               decision_review: sc,
               disposition: DISPOSITION_LIST.sample,
               caseflow_decision_date: Time.zone.now)

        task = sc.tasks.last
        task.status = "completed"
        task.updated_at = Time.zone.now + 1.minute
        vha = VhaBusinessLine.singleton
        task.completed_by_id = vha.users.sample.id
        task.save!
      end
    end

    # :reek:FeatureEnvy
    def create_hlr_with_unidentified_issue
      # this will create unidentified issue without decision date as a step 1.
      # decision review under this case will be in incomplete tab
      hlr = create_hlr_with_unidentified_issue_without_decision_date
      ri = hlr.request_issues.last
      Timecop.freeze(hlr.created_at + rand(1..4).day) do
        # step 2: remove the unidentified issue and add new issue with decision date
        # decision review now will be moved to progress tab as it will have new identified issue and decision date.
        create_step2_for_unidentified_issues(ri)
      end
    end

    # :reek:FeatureEnvy
    def create_hlr_with_unidentified_issue_without_decision_date
      hlr = create(:higher_level_review,
                   :with_intake,
                   :unidentified_issue,
                   :update_assigned_at,
                   assigned_at: rand(1.year.ago..10.minutes.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample)

      hlr.create_business_line_tasks!
      hlr.establishment_processed_at = Time.zone.now
      hlr.save

      hlr
    end

    # :reek:FeatureEnvy
    def create_sc_with_unidentified_issue
      sc = create_sc_with_unidentified_issue_without_decision_date
      ri = sc.request_issues.last

      Timecop.freeze(sc.updated_at + rand(1..5).days) do
        # step 2: remove the unidentified issue and add new issue with decision date
        # decision review now will be moved to progress tab as it will have new identified issue and decision date.
        create_step2_for_unidentified_issues(ri)
      end
    end

    # :reek:FeatureEnvy
    def create_sc_with_unidentified_issue_without_decision_date
      # step 1: create supplemental claim with unidentified issue
      create(:supplemental_claim,
             :with_intake,
             :unidentified_issue,
             :update_assigned_at,
             :processed,
             assigned_at: rand(1.year.ago..10.minutes.ago),
             benefit_type: "vha",
             description: "unidentified issue without decision date",
             claimant_type: CLAIMANT_TYPES.sample)
    end

    # :reek:FeatureEnvy
    def create_request_issues_update(request_issue)
      request_issue.save_decision_date!(rand(1.year.ago..1.day.ago))

      create(:request_issues_update,
             review: request_issue.decision_review,
             user: RequestStore[:current_user],
             submitted_at: Time.zone.now,
             processed_at: Time.zone.now,
             last_submitted_at: Time.zone.now,
             attempted_at: Time.zone.now,
             updated_at: Time.zone.now + 1.second,
             edited_request_issue_ids: [request_issue.id],
             before_request_issue_ids: [request_issue.id],
             after_request_issue_ids: [request_issue.id])
    end

    # :reek:FeatureEnvy
    def create_request_issues_update_for_withdraw(request_issue)
      create(:request_issues_update,
             review: request_issue.decision_review,
             user: RequestStore[:current_user],
             submitted_at: Time.zone.now,
             processed_at: Time.zone.now,
             edited_request_issue_ids: [],
             before_request_issue_ids: [request_issue.id],
             last_submitted_at: Time.zone.now,
             attempted_at: Time.zone.now,
             after_request_issue_ids: [request_issue.id],
             withdrawn_request_issue_ids: [request_issue.id])
    end

    # :reek:FeatureEnvy
    def create_request_issues_update_for_cancel(request_issue)
      create(:request_issues_update,
             review: request_issue.decision_review,
             user: RequestStore[:current_user],
             submitted_at: Time.zone.now,
             processed_at: Time.zone.now,
             edited_request_issue_ids: [],
             before_request_issue_ids: [request_issue.id],
             last_submitted_at: Time.zone.now,
             attempted_at: Time.zone.now,
             after_request_issue_ids: [])
    end

    # :reek:FeatureEnvy
    def create_step2_for_unidentified_issues(request_issue)
      request_issue.update(closed_status: "removed", closed_at: Time.zone.now)
      request_issue2 = create(:request_issue,
                              decision_date: 3.months.ago,
                              benefit_type: request_issue.decision_review.benefit_type,
                              nonrating_issue_category: "Other",
                              nonrating_issue_description: "issue added after removing unidentified issues",
                              decision_review: request_issue.decision_review)

      request_issue.decision_review.create_business_line_tasks!

      create(:request_issues_update,
             review: request_issue.decision_review,
             user: RequestStore[:current_user],
             submitted_at: Time.zone.now,
             processed_at: Time.zone.now,
             edited_request_issue_ids: [],
             before_request_issue_ids: [request_issue.id],
             last_submitted_at: Time.zone.now,
             attempted_at: Time.zone.now,
             after_request_issue_ids: [request_issue2.id])
    end
  end
end
