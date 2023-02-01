# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
module Seeds
  class CavcDashboardData < Base
    def initialize
      initial_id_values
    end

    def seed!
      Seeds::CavcDecisionReasonData.new.seed!
      create_cavc_dashboard_dispositions
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

    def create_cavc_dashboard_dispositions
      10.times do
        remand = create(:cavc_remand,
                        cavc_docket_number: format("%<y>2d-%<n>4d", y: @year, n: @cavc_docket_number_last_four),
                        veteran: create_veteran)
        remand.source_appeal.request_issues.map do |issue|
          CavcDashboardDisposition.create(cavc_remand: remand, request_issue_id: issue.id)
        end

        @cavc_docket_number_last_four += 1
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
