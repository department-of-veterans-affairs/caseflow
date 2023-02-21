# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
module Seeds
  class CavcDispositionToReasonData < Base
    def initialize
      initial_id_values
    end

    def seed!
      Seeds::CavcDecisionReasonData.new.seed! unless CavcDecisionReason.count > 0
      create_cavc_dispositions
      create_cavc_dashboard_issues
    end

    private

    def create_cavc_dispositions
      CavcDispositionToReasonData.create(cavc_dashboard_dispositions_id: CavcDashboardDisposition.first.id, decision_reason_id: CavcDecisionReason.first.id, basis_for_selection_id: CavcSelectionBasis.first.id )
      CavcDashboardIssue.create(cavc_dashboard: dashboard)
      end
    end

    def create_cavc_dashboard_issues
      10.times do
        remand = create(:cavc_remand,
                        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
                        veteran: create_veteran)
        dashboard = CavcDashboard.create!(cavc_remand: remand)
        CavcDashboardIssue.create(cavc_dashboard: dashboard)

        @cavc_docket_number_last_four += 1
      end
    end


end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
