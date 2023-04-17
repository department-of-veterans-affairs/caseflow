# frozen_string_literal: true

# Veterans Health Administration related seeds

module Seeds
  class VeteransHealthAdministration < Base
    PROGRAM_OFFICES = [
      "Community Care - Payment Operations Management",
      "Community Care - Veteran and Family Members Program",
      "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel",
      "Prosthetics"
    ].freeze

    IN_PROCESS_SC_TO_CREATE = 6
    IN_PROCESS_HLR_TO_CREATE = 10

    def seed!
      setup_camo_org
      setup_caregiver_org
      setup_program_offices!
      create_visn_org_teams!
      create_vha_camo
      create_vha_caregiver
      create_vha_program_office
      create_vha_visn_pre_docket_queue
      create_high_level_reviews
      create_supplemental_claims
    end

    private

    def setup_camo_org
      regular_user = create(:user, full_name: "Greg CAMOUser Camo", css_id: "CAMOUSER")
      admin_user = create(:user, full_name: "Alex CAMOAdmin Camo", css_id: "CAMOADMIN")
      camo = VhaCamo.singleton
      camo.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, camo)
    end

    def setup_caregiver_org
      regular_user = create(:user, full_name: "Edward CSPUser Caregiver", css_id: "CAREGIVERUSER")
      admin_user = create(:user, full_name: "Alvin CSPAdmin Caregiver", css_id: "CAREGIVERADMIN")
      vha_csp = VhaCaregiverSupport.singleton
      vha_csp.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, vha_csp)
    end

    def setup_program_offices!
      PROGRAM_OFFICES.each { |name| VhaProgramOffice.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Stevie VhaProgramOffice Amana", css_id: "VHAPOUSER")
      admin_user = create(:user, full_name: "Channing VhaProgramOfficeAdmin Katz", css_id: "VHAPOADMIN")

      VhaProgramOffice.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end

    def create_visn_org_teams!
      regular_user = create(:user, full_name: "Stacy VISNUser Smith", css_id: "VISNUSER")
      admin_user = create(:user, full_name: "Betty VISNAdmin Rose", css_id: "VISNADMIN")

      Constants.VISN_ORG_NAMES.visn_orgs.name.each do |name|
        visn = VhaRegionalOffice.create!(name: name, url: name)
        visn.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, visn)
      end
    end

    def create_vha_camo
      create_vha_camo_queue_assigned
      create_vha_camo_queue_in_progress
      create_vha_camo_queue_completed
    end

    def create_vha_caregiver
      create_vha_caregiver_queue_assigned
      create_vha_caregiver_queue_in_progress
      create_vha_caregiver_queue_completed
    end

    def create_supplemental_claims
      business_line_list = Organization.where(type: "BusinessLine", url: "loan-guaranty")
      business_line_list.each do |bussiness_line|
        create_list(:supplemental_claim_vha_task, 5, assigned_to: bussiness_line)
        create_supplemental_claims_dependent_claimants(bussiness_line.url.underscore)
        create_supplemental_claims_dependent_claimants(bussiness_line.url.underscore)
        create_supplemental_claims_attorney_claimants(bussiness_line.url.underscore)
        create_supplemental_claims_other_claimants(bussiness_line.url.underscore)
      end
      create_supplemental_claims_HealthCare_claimants
    end

    def create_supplemental_claims_dependent_claimants(benefit_type)
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = DependentClaimant.limit(512).where.not(participant_id: nil)
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = SupplementalClaim.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          benefit_type: benefit_type,
          veteran_is_not_claimant: true
        )
        DependentClaimant.create!(decision_review: sc, participant_id: dependent.participant_id, payee_code: "10")
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: benefit_type.to_s,
          benefit_type: benefit_type,
          decision_date: 1.month.ago
        )
        sc
      end
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, SupplementalClaim.name)
    end

    def create_supplemental_claims_attorney_claimants(benefit_type)
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = BgsAttorney.limit(512).where.not(participant_id: nil)
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = SupplementalClaim.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          benefit_type: benefit_type,
          veteran_is_not_claimant: true
        )
        AttorneyClaimant.create!(decision_review: sc, participant_id: dependent.participant_id)
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Attorney Claimant #{benefit_type}",
          benefit_type: benefit_type,
          decision_date: 1.month.ago
        )
        sc
      end
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, SupplementalClaim.name)
    end

    def create_supplemental_claims_other_claimants(benefit_type)
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = create_list(:claimant, 10, :with_unrecognized_appellant_detail, type: "OtherClaimant")
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = SupplementalClaim.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          benefit_type: benefit_type,
          veteran_is_not_claimant: true
        )
        OtherClaimant.create!(decision_review: sc, participant_id: dependent.participant_id)
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Other Claimant #{benefit_type}",
          benefit_type: benefit_type,
          decision_date: 1.month.ago
        )
        sc
      end
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, SupplementalClaim.name)
    end

    def create_supplemental_claims_health_care_claimants
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = create_list(:claimant, 10, :with_unrecognized_appellant_detail, type: "HealthcareProviderClaimant")
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = SupplementalClaim.create!(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          benefit_type: "vha",
          veteran_is_not_claimant: true
        )
        HealthcareProviderClaimant.create!(decision_review: sc, participant_id: dependent.participant_id)
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Health Provider Climant",
          benefit_type: "vha",
          decision_date: 1.month.ago
        )
        sc
      end

      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, SupplementalClaim.name)
    end

    def create_high_level_reviews
      business_line_list = BusinessLine.all
      business_line_list.each do |bussiness_line|
        create_list(:higher_level_review_vha_task, 5, assigned_to: bussiness_line)
        create_high_level_reviews_other_claimants(bussiness_line.url.underscore)
      end

    end

    def create_high_level_reviews_other_claimants(benefit_type)
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = DependentClaimant.limit(5).where.not(participant_id: nil)
      dependent_in_progress_hlrs = Array.new(IN_PROCESS_HLR_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        hlr = HigherLevelReview.create(
          veteran_file_number: veteran.file_number,
          receipt_date: Time.zone.now,
          benefit_type: benefit_type,
          informal_conference: false,
          same_office: false,
          veteran_is_not_claimant: false
        )
        DependentClaimant.create(decision_review: hlr, participant_id: dependent.participant_id, payee_code: "10")
        RequestIssue.create(
          decision_review: hlr,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Travel Benefits",
          benefit_type: benefit_type,
          decision_date: 1.month.ago
        )
        hlr
      end
      submit_claims_to_process_and_create_task(dependent_in_progress_hlrs)
      change_claim_status_to_complete(dependent_in_progress_hlrs, HigherLevelReview.name)
    end

    # submit the hlr and scr to be processed and create task
    def submit_claims_to_process_and_create_task(claim_in_process)
      claim_in_process.each do |cip|
        cip.submit_for_processing!
        cip.create_business_line_tasks!
      end
    end

    # change the status of hlr and scr to completed.
    def change_claim_status_to_complete(in_process_claims, claim_name)
      [0...2].each do |num|
        DecisionReviewTask.where(
          appeal_id: in_process_claims[num],
          appeal_type: [claim_name]
        ).each(&:completed!)
      end
    end

    def create_vha_visn_pre_docket_queue
      tabs = [:assigned, :completed, :in_progress, :on_hold]
      vha_regional_offices = VhaRegionalOffice.all
      tabs.each do |status|
        vha_regional_offices.each do |regional_office|
          create_list(:assess_documentation_task_predocket, 5, status, assigned_to: regional_office) unless status == :on_hold
          create_list(:assess_documentation_task_predocket, 5, :on_hold, assigned_to: regional_office) if status == :on_hold
        end
      end
    end

    def create_vha_camo_queue_assigned
      5.times do
        create(:vha_document_search_task, assigned_to: VhaCamo.singleton)
      end
    end

    def create_vha_camo_queue_in_progress
      5.times do
        appeal = create(:appeal)
        root_task = create(:task, appeal: appeal, assigned_to: VhaCamo.singleton)
        pre_docket_task = FactoryBot.create(
          :pre_docket_task,
          :in_progress,
          assigned_to: VhaCamo.singleton,
          appeal: appeal,
          parent: root_task
        )
        create(:task, :in_progress, assigned_to: VhaCamo.singleton, appeal: appeal, parent: pre_docket_task)
      end
    end

    def create_vha_camo_queue_completed
      5.times do
        create(
          :vha_document_search_task_with_assigned_to,
          :completed,
          assigned_to: VhaCamo.singleton
        )
      end
    end

    def create_vha_caregiver_queue_assigned
      5.times do
        create(:vha_document_search_task_with_assigned_to, assigned_to: VhaCaregiverSupport.singleton)
      end
    end

    def create_vha_caregiver_queue_in_progress
      5.times do
        create(:vha_document_search_task_with_assigned_to, :in_progress, assigned_to: VhaCaregiverSupport.singleton)
      end
    end

    def create_vha_caregiver_queue_completed
      5.times do
        create(:vha_document_search_task_with_assigned_to, :completed, assigned_to: VhaCaregiverSupport.singleton)
      end
    end

    def create_vha_program_office
      tabs = [:assigned, :in_progress, :on_hold, :ready_for_review, :completed]
      program_offices = VhaProgramOffice.all
      tabs.each do |status|
        program_offices.each do |program_office|
          if status == :on_hold
            create_list(:assess_documentation_task_predocket, 5, :on_hold, assigned_to: program_office)
          elsif status == :ready_for_review
            create_list(:assess_documentation_task_predocket, 5, :completed, :ready_for_review, assigned_to: program_office)
          else
            create_list(:assess_documentation_task_predocket, 5, status, assigned_to: program_office)
          end
        end
      end
    end
  end
end
