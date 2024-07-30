# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
module Seeds
  class CavcDashboardData < Base
    def initialize
      initial_id_values
    end

    def seed!
      Seeds::CavcSelectionBasisData.new.seed! unless CavcSelectionBasis.count > 0
      Seeds::CavcDecisionReasonData.new.seed! unless CavcDecisionReason.count > 0
      create_cavc_dashboards_with_blank_dispositions
      create_cavc_dashboards_with_selected_dispositions
      create_cavc_dashboards_with_issues
      create_appeals_with_multiple_cavc_remands
      create_appeal_with_cavc_remand_affirmed_type
    end

    private

    def initial_id_values
      @year = Time.zone.now.strftime("%y")
      @cavc_docket_number_last_four ||= 1000
      @file_number ||= 410_000_000
      @participant_id ||= 810_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 100
        @participant_id += 100
      end
      while CavcRemand.find_by(cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four))
        @cavc_docket_number_last_four += 100
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

    def create_cavc_dashboards_with_blank_dispositions
      5.times do
        remand = create(:cavc_remand,
                        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
                        veteran: create_veteran)
        CavcDashboard.create!(cavc_remand: remand)

        @cavc_docket_number_last_four += 1
      end
    end

    def create_cavc_dashboards_with_selected_dispositions
      5.times do
        remand = create(:cavc_remand,
                        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
                        veteran: create_veteran)
        dashboard = CavcDashboard.create!(cavc_remand: remand)

        dashboard.cavc_dashboard_dispositions.map do |disp|
          disp.disposition = "reversed"
          disp.save!
          cdr = CavcDispositionsToReason.create!(
            cavc_dashboard_disposition: disp,
            cavc_decision_reason: CavcDecisionReason.find_by(decision_reason: "Other due process protection")
          )
          CavcReasonsToBasis.create!(
            cavc_dispositions_to_reason: cdr,
            cavc_selection_basis: CavcSelectionBasis.find_by(basis_for_selection: "AMA Opt-in")
          )
        end

        @cavc_docket_number_last_four += 1
      end
    end

    def create_cavc_dashboards_with_issues
      10.times do
        remand = create(:cavc_remand,
                        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
                        veteran: create_veteran)
        dashboard = CavcDashboard.create!(cavc_remand: remand)
        issue = CavcDashboardIssue.create(cavc_dashboard: dashboard, issue_description: "Test")
        CavcDashboardDisposition.create(cavc_dashboard_issue: issue, cavc_dashboard: dashboard)

        @cavc_docket_number_last_four += 1
      end
    end

    def create_appeals_with_multiple_cavc_remands
      Timecop.travel 1.month.ago
      source_appeal = create(:appeal,
                             :dispatched,
                             :with_request_issues,
                             :with_decision_issue,
                             issue_count: 1,
                             veteran: create_veteran)
      user = create(:user)
      Timecop.return

      4.times do
        creation_params = {
          source_appeal_id: source_appeal.id,
          cavc_decision_type: "remand",
          cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
          cavc_judge_full_name: "Clerk",
          created_by_id: user.id,
          decision_date: 1.week.ago,
          decision_issue_ids: source_appeal.decision_issue_ids,
          instructions: "Seed remand for testing",
          represented_by_attorney: true,
          updated_by_id: user.id,
          remand_subtype: "jmr",
          judgement_date: 1.week.ago,
          mandate_date: 1.week.ago
        }

        cavc_remand = CavcRemand.create!(creation_params)
        dashboard = CavcDashboard.create!(cavc_remand: cavc_remand)
        cavc_issue = CavcDashboardIssue.create(
          cavc_dashboard: dashboard,
          benefit_type: 'compensation',
          issue_category: 'Unknown Issue Category',
          issue_description: "Lorem ipsum dolor sit amet"
        )
        disposition = CavcDashboardDisposition.create(
          cavc_dashboard_issue: cavc_issue,
          disposition: 'reversed',
          cavc_dashboard: dashboard,
        )

        other_due_process_protection = CavcDecisionReason.where(decision_reason: 'Other due process protection').first
        other_due_basis_first = CavcSelectionBasis.where(category: other_due_process_protection.basis_for_selection_category).first
        other_due_basis_second = CavcSelectionBasis.where(category: other_due_process_protection.basis_for_selection_category)[1]
        other_due_cdr = CavcDispositionsToReason.create(
          cavc_decision_reason: other_due_process_protection,
          cavc_dashboard_disposition: disposition
        )
        CavcReasonsToBasis.create!(
          cavc_dispositions_to_reason: other_due_cdr,
          cavc_selection_basis: other_due_basis_first
        )
        CavcReasonsToBasis.create!(
          cavc_dispositions_to_reason: other_due_cdr,
          cavc_selection_basis: other_due_basis_second
        )

        misapplication = CavcDecisionReason.where(decision_reason: 'Misapplication of statute/regulation/diagnostic code/caselaw').first
        CavcDispositionsToReason.create(
          cavc_decision_reason: misapplication,
          cavc_dashboard_disposition: disposition,
        )

        misapplication_regulation = CavcDecisionReason.where(decision_reason: 'Regulation', basis_for_selection_category: "misapplication_regulation").first
        mis_reg_basis = CavcSelectionBasis.where(category: misapplication_regulation.basis_for_selection_category).first
        mis_reg_cdr = CavcDispositionsToReason.create(
          cavc_decision_reason: misapplication_regulation,
          cavc_dashboard_disposition: disposition
        )
        CavcReasonsToBasis.create!(
          cavc_dispositions_to_reason: mis_reg_cdr,
          cavc_selection_basis: mis_reg_basis
        )

        @cavc_docket_number_last_four += 1
      end
    end

    def create_appeal_with_cavc_remand_affirmed_type

      Timecop.travel 1.month.ago
      source_appeal = create(:appeal,
                             :dispatched,
                             :with_request_issues,
                             :with_decision_issue,
                             issue_count: 1,
                             veteran: create_veteran)
      user = create(:user)
      Timecop.return

      creation_params = {
        source_appeal_id: source_appeal.id,
        cavc_decision_type: "affirmed",
        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
        cavc_judge_full_name: "Clerk",
        created_by_id: user.id,
        decision_date: 1.week.ago,
        decision_issue_ids: source_appeal.decision_issue_ids,
        instructions: "Seed remand for testing",
        represented_by_attorney: true,
        updated_by_id: user.id,
        judgement_date: 1.week.ago,
        mandate_date: 1.week.ago
      }

      cavc_remand = CavcRemand.create!(creation_params)
      dashboard = CavcDashboard.create!(cavc_remand: cavc_remand)
      cavc_issue = CavcDashboardIssue.create(
        cavc_dashboard: dashboard,
        benefit_type: 'compensation',
        issue_category: 'Unknown Issue Category',
        issue_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
      )
      disposition = CavcDashboardDisposition.create(
        cavc_dashboard_issue: cavc_issue,
        disposition: 'reversed',
        cavc_dashboard: dashboard,
      )

      @cavc_docket_number_last_four += 1
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
