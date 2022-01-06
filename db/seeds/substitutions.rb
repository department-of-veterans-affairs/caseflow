# frozen_string_literal: true

# Appellant Substitution seeds

module Seeds
  class Substitutions < Base
    def seed!
      setup_substitution_seeds
    end

    private

    # We will create the vet w/o date of death and update later due to task tree considerations
    def deceased_vet
      @deceased_vet ||= create(
        :veteran,
        file_number: 54_545_454,
        first_name: "Jane",
        last_name: "Deceased"
      )
    end

    def date_of_death
      30.days.ago
    end

    def create_tasks_for_pending_appeals(appeal)
      colocated_user = User.find_by_css_id("BVAAABSHIRE")
      cob_user = User.find_by_css_id("BVATCOBB")
      FoiaRequestMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      foia_parent_task = appeal.tasks.of_type(:FoiaRequestMailTask).first
      FoiaRequestMailTask.create!(appeal: appeal,
                                  parent: foia_parent_task, assigned_to: PrivacyTeam.singleton, assigned_by: cob_user)
      EvidenceOrArgumentMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      evidence_task = appeal.tasks.of_type(:EvidenceOrArgumentMailTask).first
      evidence_task.update!(status: "completed")
      create(:colocated_task,
             :translation,
             appeal: appeal,
             assigned_to: colocated_user,
             assigned_by: cob_user,
             parent: appeal.root_task)
      AddressChangeMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      address_parent_task = appeal.tasks.of_type(:AddressChangeMailTask).first
      AddressChangeMailTask.create!(appeal: appeal, parent: address_parent_task,
                                    assigned_to: PrivacyTeam.singleton, assigned_by: cob_user)
    end

    def create_tasks_for_dispatched_appeals(appeal)
      cob_user = User.find_by_css_id("BVATCOBB")
      CongressionalInterestMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      congressional_parent_task = appeal.tasks.of_type(:CongressionalInterestMailTask).first
      CongressionalInterestMailTask.create!(appeal: appeal, parent: congressional_parent_task,
                                            assigned_to: LitigationSupport.singleton, assigned_by: cob_user)
      AodMotionMailTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
      aod_parent = appeal.tasks.of_type(:AodMotionMailTask).first
      AodMotionMailTask.create!(appeal: appeal, parent: aod_parent, assigned_to: AodTeam.singleton,
                                assigned_by: cob_user)
    end

    def create_appeal_with_death_dismissal(veteran: deceased_vet, docket_type: "direct_review")
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")

      appeal = create(
        :appeal,
        :with_decision_issue, :dispatched, # trait order matters to ensure correct `closed_status` on RI
        disposition: "dismissed_death",
        number_of_claimants: 1,
        veteran: veteran,
        docket_type: docket_type,
        receipt_date: date_of_death + 5.days,
        closest_regional_office: "RO17",
        associated_judge: judge,
        associated_attorney: attorney
      )
      create_tasks_for_dispatched_appeals(appeal)
    end

    def create_pending_appeal(veteran: deceased_vet, docket_type: "direct_review")
      attorney = User.find_by_css_id("BVASCASPER1")
      judge = User.find_by_css_id("BVAAABSHIRE")

      appeal = create(
        :appeal,
        :at_attorney_drafting,
        number_of_claimants: 1,
        veteran: veteran,
        docket_type: docket_type,
        receipt_date: date_of_death + 5.days,
        closest_regional_office: "RO17",
        associated_judge: judge,
        associated_attorney: attorney
      )
      create_tasks_for_pending_appeals(appeal)
    end

    def create_deceased_vet_and_dismissed_appeals
      ActiveRecord::Base.transaction do
        # Create appeals for each docket type
        %w[direct_review evidence_submission hearing].each do |docket_type|
          create_appeal_with_death_dismissal(veteran: deceased_vet, docket_type: docket_type)
          create_pending_appeal(veteran: deceased_vet, docket_type: docket_type)
        end

        # Need to set date_of_death after creating appeal or various tasks won't get created
        deceased_vet.update!(date_of_death: date_of_death)
      end
    end

    def setup_substitution_seeds
      create_deceased_vet_and_dismissed_appeals
    end
  end
end
