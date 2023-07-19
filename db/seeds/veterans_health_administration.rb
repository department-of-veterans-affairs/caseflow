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
      create_higher_level_reviews
      create_supplemental_claims
      add_vha_user_to_be_vha_business_line_member
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
      # create_vha_camo_queue_in_progress
      create_vha_camo_queue_completed
    end

    def create_vha_caregiver
      create_vha_caregiver_queue_assigned
      # create_vha_caregiver_queue_in_progress
      create_vha_caregiver_queue_completed
    end

    def create_higher_level_reviews
      benefit_type_list = Constants::BENEFIT_TYPES.keys.map(&:to_s)
      benefit_type_list.each do |benefit_type|
        3.times do
          create_hlr_with_claimant(benefit_type, :veteran_claimant)
          create_hlr_with_claimant(benefit_type, :dependent_claimant)
          create_hlr_with_claimant(benefit_type, :attorney_claimant)
          create_hlr_with_claimant(benefit_type, :healthcare_claimant)
          create_hlr_with_claimant(benefit_type, :other_claimant)
        end


        # benefit_claim_type = { benefit_type: business_line.url.underscore, claim_type: "HLR" }
        # create_list(:higher_level_review_vha_task, 5, assigned_to: business_line)
        # create_claims_with_dependent_claimants(benefit_claim_type)
        # create_claims_with_attorney_claimants(benefit_claim_type)
        # create_claims_with_other_claimants(benefit_claim_type)
      end
      # create_claims_with_health_care_claimants("HLR")
    end

    def create_supplemental_claims
      benefit_type_list = Constants::BENEFIT_TYPES.keys.map(&:to_s)
      benefit_type_list.each do |benefit_type|
        3.times do
          create_sc_with_claimant(benefit_type, :veteran_claimant)
          create_sc_with_claimant(benefit_type, :dependent_claimant)
          create_sc_with_claimant(benefit_type, :attorney_claimant)
          create_sc_with_claimant(benefit_type, :healthcare_claimant)
          create_sc_with_claimant(benefit_type, :other_claimant)
        end
        # benefit_claim_type = { benefit_type: business_line.url.underscore, claim_type: "supplemental" }
        # create_list(:supplemental_claim_vha_task, 5, assigned_to: business_line)
        # create_claims_with_dependent_claimants(benefit_claim_type)
        # create_claims_with_attorney_claimants(benefit_claim_type)
        # create_claims_with_other_claimants(benefit_claim_type)
      end
      # create_claims_with_health_care_claimants("supplemental")
    end

    def create_claims_with_dependent_claimants(arg = {})
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      participant_id = rand(1_000_000...999_999_999)
      dependents = create_list(:claimant, 20, type: "DependentClaimant", participant_id: participant_id.to_s)
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = create_claim(arg[:benefit_type], arg[:claim_type], veteran)

        DependentClaimant.create!(decision_review: sc, participant_id: dependent.participant_id, payee_code: "10")
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel",
          nonrating_issue_description: arg[:benefit_type].to_s,
          benefit_type: arg[:benefit_type],
          decision_date: 1.month.ago
        )
        sc
      end
      name = (arg[:claim_type] == "supplemental") ? SupplementalClaim.name : HigherLevelReview.name
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, name)
    end

    def create_claims_with_attorney_claimants(benefit_and_claim = {})
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = create_list(:bgs_attorney, 20)
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]

        sc = create_claim(benefit_and_claim[:benefit_type], benefit_and_claim[:claim_type], veteran)

        AttorneyClaimant.create!(decision_review: sc, participant_id: dependent.participant_id, payee_code: "15")
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Attorney Claimant #{benefit_and_claim[:benefit_type]}",
          benefit_type: benefit_and_claim[:benefit_type],
          decision_date: 1.month.ago
        )
        sc
      end
      name = (benefit_and_claim[:claim_type] == "supplemental") ? SupplementalClaim.name : HigherLevelReview.name
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, name)
    end

    def create_claims_with_other_claimants(benefit_and_claim_arg = {})
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = create_list(:claimant, 10, :with_unrecognized_appellant_detail, type: "OtherClaimant")
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = create_claim(benefit_and_claim_arg[:benefit_type], benefit_and_claim_arg[:claim_type], veteran)

        OtherClaimant.create!(decision_review: sc, participant_id: dependent.participant_id, payee_code: "20")
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Other Claimant #{benefit_and_claim_arg[:benefit_type]}",
          benefit_type: benefit_and_claim_arg[:benefit_type],
          decision_date: 1.month.ago
        )
        sc
      end
      name = (benefit_and_claim_arg[:claim_type] == "supplemental") ? SupplementalClaim.name : HigherLevelReview.name
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, name)
    end

    def create_claims_with_health_care_claimants(claim_type = "supplemental")
      veterans = Veteran.limit(10).where.not(participant_id: nil)
      dependents = create_list(:claimant, 10, :with_unrecognized_appellant_detail, type: "HealthcareProviderClaimant")
      dependent_in_progress_scs = Array.new(IN_PROCESS_SC_TO_CREATE).map do
        veteran = veterans[rand(0...veterans.size)]
        dependent = dependents[rand(0...dependents.size)]
        sc = create_claim("vha", claim_type, veteran)

        HealthcareProviderClaimant.create!(decision_review: sc, participant_id: dependent.participant_id, payee_code: "12")
        RequestIssue.create!(
          decision_review: sc,
          nonrating_issue_category: "Beneficiary Travel | Special Mode",
          nonrating_issue_description: "Health Provider Climant",
          benefit_type: "vha",
          decision_date: 1.month.ago
        )
        sc
      end
      name = (claim_type == "supplemental") ? SupplementalClaim.name : HigherLevelReview.name
      submit_claims_to_process_and_create_task(dependent_in_progress_scs)
      change_claim_status_to_complete(dependent_in_progress_scs, name)
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

    def create_claim(*arg)
      sc = if arg[1].casecmp("supplemental").zero?
             SupplementalClaim.create!(
               veteran_file_number: arg[2].file_number,
               receipt_date: Time.zone.now,
               benefit_type: arg[0],
               veteran_is_not_claimant: true
             )
           else
             HigherLevelReview.create(
               veteran_file_number: arg[2].file_number,
               receipt_date: Time.zone.now,
               benefit_type: arg[0],
               informal_conference: false,
               same_office: false,
               veteran_is_not_claimant: true
             )
           end
      sc
    end

    def create_hlr_with_claimant(benefit_type, claimant_type = nil)
      case claimant_type
      when :dependent_claimant
        hlr = create(:higher_level_review, :with_request_issue, :processed, veteran_is_not_claimant: true, benefit_type: benefit_type, number_of_claimants: 1)
      when :attorney_claimant
        hlr = create(:higher_level_review, :with_request_issue, :processed, veteran_is_not_claimant: true, has_attorney_claimant: true, benefit_type: benefit_type)
      when :healthcare_claimant
        hlr = create(:higher_level_review, :with_request_issue, :processed, veteran_is_not_claimant: true, has_healthcare_provider_claimant: true, benefit_type: benefit_type)
      when :other_claimant
        hlr = create(:higher_level_review, :with_request_issue, :processed, veteran_is_not_claimant: true, has_unrecognized_appellant: true, benefit_type: benefit_type)
      else
        hlr = create(:higher_level_review, :with_request_issue, :processed, veteran_is_not_claimant: false, benefit_type: benefit_type, number_of_claimants: 1)
      end
      hlr.create_business_line_tasks!
    end

    def create_sc_with_claimant(benefit_type, claimant_type = nil)
      case claimant_type
      when :dependent_claimant
        sc = create(:supplemental_claim, :with_request_issue, :processed, veteran_is_not_claimant: true, benefit_type: benefit_type, number_of_claimants: 1)
      when :attorney_claimant
        sc = create(:supplemental_claim, :with_request_issue, :processed, veteran_is_not_claimant: true, has_attorney_claimant: true, benefit_type: benefit_type)
      when :healthcare_claimant
        sc = create(:supplemental_claim, :with_request_issue, :processed, veteran_is_not_claimant: true, has_healthcare_provider_claimant: true, benefit_type: benefit_type)
      when :other_claimant
        sc = create(:supplemental_claim, :with_request_issue, :processed, veteran_is_not_claimant: true, has_unrecognized_appellant: true, benefit_type: benefit_type)
      else
        sc = create(:supplemental_claim, :with_request_issue, :processed, veteran_is_not_claimant: false, benefit_type: benefit_type, number_of_claimants: 1)
      end
      sc.create_business_line_tasks!
    end

    def create_vha_visn_pre_docket_queue
      tabs = [:assigned, :completed, :in_progress, :on_hold]
      vha_regional_offices = VhaRegionalOffice.all
      vha_program_offices = VhaProgramOffice.all
      tabs.each do |status|
        vha_regional_offices.each do |regional_office|
          # We want to also populate the VhaProgramOffice queue's in_progress tabs, so loop through them here also
          vha_program_offices.each do |program_office|
            po_task = create(:assess_documentation_task, :assigned, assigned_to: program_office)
            if status == :completed
              # VISN completed tasks will populate the PO office 'ready for review' tab
              ro_task = create(:assess_documentation_task, parent: po_task, assigned_to: regional_office)
              ro_task.completed!
            else
              # assigned, in_progress, and on_hold status will populate in the PO office 'on_hold' tab
              create(:assess_documentation_task, status, parent: po_task, assigned_to: regional_office)
            end
          end
        end
      end
    end

    def create_vha_camo_queue_assigned
      5.times do
        create(:vha_document_search_task, :assigned, assigned_to: VhaCamo.singleton)
      end
    end

    # This data needs to come from cases assigned to a PO, not by manually setting these attributes
    # def create_vha_camo_queue_in_progress
    #   5.times do
    #     appeal = create(:appeal)
    #     root_task = create(:task, appeal: appeal, assigned_to: VhaCamo.singleton)
    #     pre_docket_task = FactoryBot.create(
    #       :pre_docket_task,
    #       :in_progress,
    #       assigned_to: VhaCamo.singleton,
    #       appeal: appeal,
    #       parent: root_task
    #     )
    #     create(:task, :in_progress, assigned_to: VhaCamo.singleton, appeal: appeal, parent: pre_docket_task)
    #   end
    # end

    def create_vha_camo_queue_completed
      5.times do
        task = create(:vha_document_search_task, assigned_to: VhaCamo.singleton)
        task.completed!
      end
    end

    def create_vha_caregiver_queue_assigned
      5.times do
        create(:vha_document_search_task, assigned_to: VhaCaregiverSupport.singleton)
      end
    end

    # This data needs to come from cases assigned to a PO, not by manually setting these attributes
    # def create_vha_caregiver_queue_in_progress
    #   5.times do
    #     create(:vha_document_search_task, :in_progress, assigned_to: VhaCaregiverSupport.singleton)
    #   end
    # end

    def create_vha_caregiver_queue_completed
      5.times do
        task = create(:vha_document_search_task, assigned_to: VhaCaregiverSupport.singleton)
        task.completed!
      end
    end

    def create_vha_program_office
      tabs = [:assigned, :in_progress, :on_hold, :ready_for_review, :completed]
      program_offices = VhaProgramOffice.all
      tabs.each do |status|
        program_offices.each do |program_office|
          if status == :on_hold
            # this data should be implemented by cases being assigned to a VISN, not manually setting attributes
            # create_list(:assess_documentation_task, 5, :on_hold, assigned_to: program_office)
          elsif status == :ready_for_review
            # this data should be implemented by cases being completed! by as VISN, not manually setting attributes
            # create_list(:assess_documentation_task, 5, :completed, :ready_for_review, assigned_to: program_office)
          elsif status == :completed
            5.times do
              task = create(:assess_documentation_task, assigned_to: program_office)
              task.completed!
            end
          else
            create_list(:assess_documentation_task, 5, assigned_to: program_office)
          end
        end
      end
    end

    # Ensure all VHA users are made members of the VHA Business Line.
    def add_vha_user_to_be_vha_business_line_member
      # Get list of all the users who are the members of VHA Camo, Vha Program Office and VISN
      # basically any organization whose type starts with Vha%
      user_list = User.joins("INNER JOIN Organizations_users ou On Users.id = Ou.user_id
        INNER JOIN Organizations o on o.id = ou.organization_id")
        .where("o.type like ?", "Vha%")
        .distinct
      # organization = BusinessLine.where(name:)
      organization = Organization.find_by_name_or_url("Veterans Health Administration")
      user_list.each do |user|
        organization.add_user(user)
      end
    end
  end
end
