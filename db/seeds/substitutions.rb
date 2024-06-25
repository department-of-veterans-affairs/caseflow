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
      params = { first_name: "JaneDeceased", last_name: "SubstitutionsSeed" }
      params[:file_number] = 54_545_454 unless Veteran.find_by(file_number: 54_545_454)
      @deceased_vet ||= create(:veteran, params)
    end

    def date_of_death
      30.days.ago
    end

    def bvaaabshire
      @bvaaabshire ||= User.find_by_css_id("BVAAABSHIRE")
    end

    def bvatcobb
      @bvatcobb ||= User.find_by_css_id("BVATCOBB")
    end

    def bvascasper1
      bvascasper1 ||= User.find_by_css_id("BVASCASPER1")
    end

    # :reek:FeatureEnvy
    def create_tasks_for_pending_appeals(appeal)
      colocated_user = bvaaabshire
      cob_user = bvatcobb
      foia_parent_task = FoiaRequestMailTask.create!(appeal: appeal, parent: appeal.root_task,
                                                     assigned_to: MailTeam.singleton)
      FoiaRequestMailTask.create!(appeal: appeal, parent: foia_parent_task,
                                  assigned_to: PrivacyTeam.singleton, assigned_by: cob_user)
      create(:colocated_task,
             :translation,
             appeal: appeal,
             assigned_to: colocated_user,
             assigned_by: cob_user,
             parent: appeal.root_task)
      address_parent_task = AddressChangeMailTask.create!(appeal: appeal, parent: appeal.root_task,
                                                          assigned_to: MailTeam.singleton)
      AddressChangeMailTask.create!(appeal: appeal, parent: address_parent_task,
                                    assigned_to: PrivacyTeam.singleton, assigned_by: cob_user)
    end

    def create_completed_tasks_for_pending_appeal(appeal)
      cob_user = bvatcobb
      EvidenceOrArgumentMailTask
        .create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
        .completed!
      parent = ReconsiderationMotionMailTask.create!(appeal: appeal, parent: appeal.root_task,
                                                            assigned_to: MailTeam.singleton)
      ReconsiderationMotionMailTask
        .create!(appeal: appeal, parent: parent, assigned_to: LitigationSupport.singleton, assigned_by: cob_user)
        .completed!
    end

    def create_cancelled_tasks(appeal)
      EvidenceSubmissionWindowTask
        .create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
        .cancelled!
      ScheduleHearingTask
        .create!(appeal: appeal, parent: appeal.root_task, assigned_to: MailTeam.singleton)
        .cancelled!
    end

    def create_appeal_with_death_dismissal(veteran: deceased_vet, docket_type: "direct_review")
      create(
        :appeal,
        :with_decision_issue, :dispatched, # trait order matters to ensure correct `closed_status` on RI
        disposition: "dismissed_death",
        number_of_claimants: 1,
        veteran: veteran,
        docket_type: docket_type,
        receipt_date: date_of_death + 5.days,
        closest_regional_office: "RO17",
        associated_judge: bvaaabshire,
        associated_attorney: bvascasper1
      )
    end

    def create_pending_appeal(veteran: deceased_vet, docket_type: "direct_review")
      appeal = create(
        :appeal,
        :at_attorney_drafting,
        number_of_claimants: 1,
        veteran: veteran,
        docket_type: docket_type,
        receipt_date: date_of_death + 5.days,
        closest_regional_office: "RO17",
        associated_judge: bvaaabshire,
        associated_attorney: bvascasper1
      )
      create_tasks_for_pending_appeals(appeal)
      create_completed_tasks_for_pending_appeal(appeal)
      create_cancelled_tasks(appeal)
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
