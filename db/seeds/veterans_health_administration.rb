# frozen_string_literal: true

# Veterans Health Administration related seeds

module Seeds
  class VeteransHealthAdministration < Base
    CLAIMANT_TYPES = [
      :veteran_claimant,
      :dependent_claimant,
      :attorney_claimant,
      :healthcare_claimant,
      :other_claimant,
      :other_claimant_not_listed
    ].freeze

    BENEFIT_TYPE_LIST = Constants::BENEFIT_TYPES.keys.map(&:to_s).freeze

    def seed!
      create_vha_camo
      create_vha_caregiver
      create_vha_program_office
      create_vha_visn_pre_docket_queue
      create_higher_level_reviews
      create_supplemental_claims
      create_specialty_case_team_tasks
      add_vha_user_to_be_vha_business_line_member
    end

    private

    def create_vha_camo
      create_vha_camo_queue_assigned
      create_vha_camo_queue_completed
    end

    def create_vha_caregiver
      create_vha_caregiver_queue_assigned
      create_vha_caregiver_queue_in_progress
      create_vha_caregiver_queue_completed
    end

    def create_higher_level_reviews
      BENEFIT_TYPE_LIST.each do |benefit_type|
        3.times do
          CLAIMANT_TYPES.each do |claimant_type|
            create_hlr_with_claimant(benefit_type, claimant_type)
          end
        end
      end
    end

    def create_supplemental_claims
      BENEFIT_TYPE_LIST.each do |benefit_type|
        3.times do
          CLAIMANT_TYPES.each do |claimant_type|
            create_sc_with_claimant(benefit_type, claimant_type)
            create_sc_remand(benefit_type, claimant_type)
          end
        end
      end
    end

    def create_hlr_with_claimant(benefit_type, claimant_type)
      hlr = create(
        :higher_level_review,
        :with_request_issue,
        :processed,
        benefit_type: benefit_type,
        claimant_type: claimant_type,
        number_of_claimants: 1
      )
      hlr.create_business_line_tasks!
    end

    def create_sc_with_claimant(benefit_type, claimant_type)
      sc = create(
        :supplemental_claim,
        :with_request_issue,
        :processed,
        benefit_type: benefit_type,
        claimant_type: claimant_type,
        number_of_claimants: 1
      )
      sc.create_business_line_tasks!
    end

    def create_sc_remand(benefit_type, claimant_type)
      sc = create(
        :remand,
        benefit_type: benefit_type,
        claimant_type: claimant_type,
        number_of_claimants: 1
      )
      sc.create_business_line_tasks!
    end

    # :reek:NestedIterators
    # this method is creating most of the data, but we can't get around it because of how many PO/VISN combos there are
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
              # completed tasks will populate the PO office 'ready for review' tab
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
      5.times { create(:vha_document_search_task, :assigned, assigned_to: VhaCamo.singleton) }
    end

    def create_vha_camo_queue_completed
      5.times do
        task = create(:vha_document_search_task, assigned_to: VhaCamo.singleton)
        task.completed!
      end
    end

    def create_vha_caregiver_queue_assigned
      5.times { create(:vha_document_search_task, assigned_to: VhaCaregiverSupport.singleton) }
    end

    def create_vha_caregiver_queue_in_progress
      5.times { create(:vha_document_search_task, :in_progress, assigned_to: VhaCaregiverSupport.singleton) }
    end

    def create_vha_caregiver_queue_completed
      5.times do
        task = create(:vha_document_search_task, assigned_to: VhaCaregiverSupport.singleton)
        task.completed!
      end
    end

    # :reek:FeatureEnvy
    def create_specialty_case_team_action_required
      tasks = create_list(:specialty_case_team_assign_task, 5, :action_required)
      tasks.last.appeal.veteran.date_of_death = 2.weeks.ago
      tasks.last.appeal.veteran.save
    end

    # :reek:FeatureEnvy
    def create_specialty_case_team_completed
      tasks = create_list(:specialty_case_team_assign_task, 5, :completed)
      tasks.last.appeal.veteran.date_of_death = 2.weeks.ago
      tasks.last.appeal.veteran.save
    end

    def create_specialty_case_team_assigned
      create_list(:specialty_case_team_assign_task, 5)
    end

    def create_specialty_case_team_tasks
      create_specialty_case_team_action_required
      create_specialty_case_team_completed
      create_specialty_case_team_assigned
    end

    # :reek:FeatureEnvy
    def create_vha_program_office
      # on_hold and ready_for_review tabs are populated by populating the VISN queues linked to PO orgs
      tabs = [:assigned, :in_progress, :completed]
      program_offices = VhaProgramOffice.all
      tabs.each do |status|
        program_offices.each do |program_office|
          3.times do
            task = create(:assess_documentation_task, assigned_to: program_office)
            task.in_progress! if status == :in_progress
            task.completed! if status == :completed
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

      user_list.each do |user|
        VhaBusinessLine.singleton.add_user(user)
      end
    end
  end
end
