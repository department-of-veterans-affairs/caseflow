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
      create_seeds_for_change_history
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
        # Adds hlr in in-progress tab with no decision date
        create_hlr_without_decision_date
        # Adds Prior Decision Date in the HLR
        create_hlr_with_decision_date
        # # adds Withdrawn status
        create_withdrawn_hlr
        create_cancelled_hlr
        create_hlr_with_updated_assigned_at
        # create_hlr_completed
        create_hlr_with_disposition
        create_hlr_with_unidentified_issue
        create_hlr_with_unidentified_issue_without_decision_date
      end
    end

    def create_sc_seeds_for_change_history
      15.times do
        create_sc_with_disposition
        # create_sc_completed
        create_sc_with_updated_assigned_at
        create_cancelled_sc
        create_withdrawn_sc
        create_sc_without_decision_date
        create_sc_with_decision_date
        create_sc_with_unidentified_issue
        create_sc_with_unidentified_issue_without_decision_date
      end
    end

    def create_hlr_seed(*args)
      claimant_type, issue_type = args
      hlr = create(:higher_level_review,
                   :with_specific_issue_type,
                   :requires_processing,
                   benefit_type: "vha",
                   decision_date: 4.months.ago,
                   claimant_type: claimant_type,
                   issue_type: issue_type,
                   number_of_claimants: 1)
      hlr.create_business_line_tasks!
    end

    def create_sc_seeds(*args)
      claimant_type, issue_type = args
      sc = create(:supplemental_claim,
                  :with_specific_issue_type,
                  :requires_processing,
                  :with_intake,
                  benefit_type: "vha",
                  decision_date: 4.months.ago,
                  claimant_type: claimant_type,
                  issue_type: issue_type,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!
    end

    # Inserts hlr with or with out decision date.
    # :reek:FeatureEnvy
    def create_hlr_with_decision_date
      create(:higher_level_review,
             :with_intake,
             :with_specific_issue_type,
             :processed,
             :create_business_line,
             decision_date: rand(1.year.ago..1.day.ago),
             benefit_type: "vha",
             claimant_type: CLAIMANT_TYPES.sample,
             issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
             number_of_claimants: 1)
    end

    # :reek:FeatureEnvy
    def create_hlr_without_decision_date
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_specific_issue_type,
                   :processed,
                   :create_business_line,
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   number_of_claimants: 1)
      hlr.create_business_line_tasks!
      hlr.establishment_processed_at = Time.zone.now
      hlr.save
    end

    # :reek:FeatureEnvy
    def create_sc_with_decision_date
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_specific_issue_type,
                  :processed,
                  decision_date: rand(1.year.ago..1.day.ago),
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!

      sc.establishment_processed_at = Time.zone.now
      sc.save
    end

    # :reek:FeatureEnvy
    def create_sc_without_decision_date
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_specific_issue_type,
                  :processed,
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!

      sc.establishment_processed_at = Time.zone.now
      sc.save
    end

    def create_withdrawn_hlr
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_specific_issue_type,
                   :processed,
                   benefit_type: "vha",
                   decision_date: Time.zone.now,
                   withdraw: true,
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   number_of_claimants: 1)
      hlr.create_business_line_tasks!
    end

    def create_withdrawn_sc
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_specific_issue_type,
                  :processed,
                  benefit_type: "vha",
                  decision_date: Time.zone.now,
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  withdraw: true,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!
    end

    # :reek:FeatureEnvy
    def create_cancelled_hlr
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_specific_issue_type,
                   decision_date: rand(1.year.ago..1.day.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   number_of_claimants: 1)
      hlr.create_business_line_tasks!
      ri = RequestIssue.find_by(decision_review: hlr)
      ri.remove!
      task = Task.find_by(appeal: hlr)
      task.status = "cancelled"
      task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
      task.save
    end

    # :reek:FeatureEnvy
    def create_cancelled_sc
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_specific_issue_type,
                  decision_date: rand(1.year.ago..1.day.ago),
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!
      ri = RequestIssue.find_by(decision_review: sc)
      ri.remove!
      task = Task.find_by(appeal: sc)
      task.status = "cancelled"
      task.cancelled_by_id = VhaBusinessLine.singleton.users.sample.id
      task.save
    end

    # updates assigned dates after hlr is created
    # :reek:FeatureEnvy
    def create_hlr_with_updated_assigned_at
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_specific_issue_type,
                   :processed,
                   decision_date: rand(1.year.ago..1.day.ago),
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   number_of_claimants: 1)
      hlr.create_business_line_tasks!

      task = Task.find_by(appeal: hlr)
      task.assigned_at = rand(1.year.ago..1.day.ago)
      task.save!
    end

    # :reek:FeatureEnvy
    def create_sc_with_updated_assigned_at
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_specific_issue_type,
                  :processed,
                  decision_date: rand(1.year.ago..1.day.ago),
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                  number_of_claimants: 1)
      sc.create_business_line_tasks!

      task = Task.find_by(appeal: sc)
      task.assigned_at = rand(1.year.ago..1.day.ago)
      task.save!
    end

    # adds hlr with random disposition.
    # :reek:FeatureEnvy
    def create_hlr_with_disposition
      hlr = create(:higher_level_review,
                   :with_intake,
                   :with_specific_issue_type,
                   :with_disposition,
                   :with_update_users,
                   decision_date: rand(1.year.ago..1.day.ago),
                   claimant_type: CLAIMANT_TYPES.sample,
                   issue_type: Constants::ISSUE_CATEGORIES["vha"].sample,
                   benefit_type: "vha",
                   disposition: DISPOSITION_LIST.sample)
      hlr.create_business_line_tasks!
      task = Task.find_by(appeal: hlr)
      task.status = "completed"
      vha = VhaBusinessLine.singleton
      task.completed_by_id = vha.users.sample.id
      task.save!
    end

    # :reek:FeatureEnvy
    def create_sc_with_disposition
      sc = create(:supplemental_claim,
                  :with_intake,
                  :with_request_issue,
                  :with_disposition,
                  :with_update_users,
                  claimant_type: CLAIMANT_TYPES.sample,
                  disposition: DISPOSITION_LIST.reject { |disp| disp == "DTA Error" }.sample,
                  benefit_type: "vha")
      sc.create_business_line_tasks!

      task = Task.find_by(appeal: sc)
      task.status = "completed"
      vha = VhaBusinessLine.singleton
      task.completed_by_id = vha.users.sample.id
      task.save!
    end

    def create_hlr_with_unidentified_issue
      hlr = create(:higher_level_review,
                   :with_intake,
                   :unidentified_issue,
                   :with_update_users,
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample,
                   decision_date: rand(1.year.ago..1.day.ago))

      hlr.create_business_line_tasks!
    end

    def create_hlr_with_unidentified_issue_without_decision_date
      hlr = create(:higher_level_review,
                   :with_intake,
                   :unidentified_issue,
                   :with_update_users,
                   benefit_type: "vha",
                   claimant_type: CLAIMANT_TYPES.sample)

      hlr.create_business_line_tasks!
      hlr.establishment_processed_at = Time.zone.now
      hlr.save
    end

    def create_sc_with_unidentified_issue
      sc = create(:supplemental_claim,
                  :with_intake,
                  :unidentified_issue,
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample,
                  decision_date: rand(1.year.ago..1.day.ago))
      sc.create_business_line_tasks!
    end

    def create_sc_with_unidentified_issue_without_decision_date
      sc = create(:supplemental_claim,
                  :with_intake,
                  :unidentified_issue,
                  benefit_type: "vha",
                  claimant_type: CLAIMANT_TYPES.sample)
      sc.create_business_line_tasks!

      sc.establishment_processed_at = Time.zone.now
      sc.save
    end
  end
end
