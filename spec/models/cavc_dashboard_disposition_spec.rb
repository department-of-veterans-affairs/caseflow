# frozen_string_literal: true

describe CavcDashboardDisposition, :postgres do
  let(:cavc_remand) { create(:cavc_remand) }
  let(:cavc_dashboard) { CavcDashboard.create(cavc_remand: cavc_remand) }

  before do
    RequestStore.store[:current_user] = User.system_user
  end

  context "validates" do
    it "CAVC remand presence" do
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.create!(cavc_dashboard: cavc_dashboard, disposition: "N/A") }.not_to raise_error
    end

    it "disposition presence on update only" do
      # nil disposition on initial save is allowed
      dashboard_disposition = described_class.new(cavc_dashboard: cavc_dashboard)
      expect { dashboard_disposition.save! }.not_to raise_error

      # since the record already exists in the DB, this save! is considered an update by ActiveRecord
      expect { dashboard_disposition.save! }.to raise_error(ActiveRecord::RecordInvalid)

      dashboard_disposition.disposition = "N/A"
      expect { dashboard_disposition.save! }.not_to raise_error
    end

    it "disposition value must be in enum" do
      dashboard_disposition = described_class.new

      Constants::CAVC_DASHBOARD_DISPOSITIONS.each do |k, v|
        expect { dashboard_disposition.disposition = k }.not_to raise_error
        expect { dashboard_disposition.disposition = v }.not_to raise_error
      end
      expect { dashboard_disposition.disposition = "invalid" }.to raise_error(ArgumentError)
    end

    it "only a single issue can be linked to disposition" do
      expect do
        described_class.create!(cavc_dashboard: cavc_dashboard, request_issue_id: 1, cavc_dashboard_issue_id: 1)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
