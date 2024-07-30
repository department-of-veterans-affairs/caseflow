# frozen_string_literal: true

describe CavcDashboard, :postgres do
  let(:cavc_remand) { create(:cavc_remand) }
  let(:cavc_dashboard) { CavcDashboard.create(cavc_remand: cavc_remand) }

  context "validates" do
    it "validates CAVC remand presence on create and update" do
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)

      cavc_dashboard.cavc_remand = nil
      expect { cavc_dashboard.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "validates dates and docket numbers on update only" do
      cavc_dashboard.board_decision_date = nil
      cavc_dashboard.board_docket_number = nil
      cavc_dashboard.cavc_decision_date = nil
      cavc_dashboard.cavc_docket_number = nil

      expect(cavc_dashboard.valid?).to eq false
      expect(cavc_dashboard.errors.details.count).to eq 4

      new_dashboard = CavcDashboard.new
      new_dashboard.cavc_remand = create(:cavc_remand)
      expect(new_dashboard.valid?).to be true
    end
  end

  context "when created" do
    it "sets fields from cavc_remand" do
      expect(cavc_dashboard.board_decision_date).to eq cavc_remand.source_appeal.decision_date
      expect(cavc_dashboard.board_docket_number).to eq cavc_remand.source_appeal.stream_docket_number
      expect(cavc_dashboard.cavc_decision_date).to eq cavc_remand.decision_date
      expect(cavc_dashboard.cavc_docket_number).to eq cavc_remand.cavc_docket_number
    end

    it "correctly sets joint_motion_for_remand boolean" do
      # default cavc_remand factory is remand/jmr_jmpr
      dashboard_1 = cavc_dashboard
      dashboard_2 = described_class.create(cavc_remand: create(:cavc_remand, remand_subtype: "jmr"))
      dashboard_3 = described_class.create(cavc_remand: create(:cavc_remand, remand_subtype: "jmpr"))
      dashboard_4 = described_class.create(cavc_remand: create(:cavc_remand, remand_subtype: "mdr"))
      dashboard_5 = described_class.create(cavc_remand: create(:cavc_remand,
                                                               cavc_decision_type: "straight_reversal",
                                                               remand_subtype: nil))

      expect(dashboard_1.joint_motion_for_remand).to eq true
      expect(dashboard_2.joint_motion_for_remand).to eq true
      expect(dashboard_3.joint_motion_for_remand).to eq true
      expect(dashboard_4.joint_motion_for_remand).to eq false
      expect(dashboard_5.joint_motion_for_remand).to eq false
    end
  end

  it "#remand_request_issues returns array of remand appeal's issues" do
    expect(cavc_dashboard.remand_request_issues.count).to eq cavc_remand.remand_appeal.request_issues.count
  end
end
