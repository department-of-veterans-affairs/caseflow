# frozen_string_literal: true

describe CavcDispositionsToReason, :postgres do
  let(:cavc_remand) { create(:cavc_remand) }
  let(:cavc_dashboard) { CavcDashboard.create(cavc_remand: cavc_remand) }
  let(:cavc_dashboard_disposition) { CavcDashboardDisposition.create(cavc_dashboard: cavc_dashboard) }
  let(:cavc_dispositions_to_reason) {
    CavcDispositionsToReason.create(cavc_dashboard_disposition: cavc_dashboard_disposition) }

  context "validates" do
    it "validates CAVC Disposition To Reason presence on create" do
      expect {  described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
