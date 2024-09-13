# frozen_string_literal: true

require "appeals_tied_to_avljs_and_vljs_query"

RSpec.describe AppealsTiedToAvljsAndVljsQuery do
  describe ".tied_appeals" do
    let(:docket_coordinator) { instance_double(DocketCoordinator) }
    let(:dockets) { {} }
    let(:vlj_user_ids) { [1, 2, 3] }

    before do
      allow(DocketCoordinator).to receive(:new).and_return(docket_coordinator)
      allow(docket_coordinator).to receive(:dockets).and_return(dockets)
      allow(described_class).to receive(:vlj_user_ids).and_return(vlj_user_ids)
    end

    context "when there is a :legacy docket" do
      let(:legacy_docket) { instance_double("LegacyDocket") }
      let(:appeals_tied_to_avljs_and_vljs) { [{ docket_number: "123" }, { docket_number: "456" }] }
      let(:unique_appeals) { [{ docket_number: "123" }] }

      before do
        dockets[:legacy] = legacy_docket
        allow(legacy_docket).to receive(:appeals_tied_to_avljs_and_vljs).and_return(appeals_tied_to_avljs_and_vljs)
        allow(described_class).to receive(:legacy_rows)
          .with(appeals_tied_to_avljs_and_vljs, :legacy)
          .and_return(unique_appeals)
      end

      it "processes legacy dockets correctly" do
        expect(described_class.tied_appeals).to eq(unique_appeals)
      end
    end

    context "when there is a non-legacy docket" do
      let(:non_legacy_docket) { instance_double("DirectReviewDocket") }
      let(:tied_appeals) { [{ docket_number: "789" }, { docket_number: "012" }] }
      let(:ama_rows) { [{ docket_number: "789" }] }
      let(:vlj_user_ids) { [1, 2, 3] }

      before do
        dockets[:other] = non_legacy_docket
        allow(described_class).to receive(:vlj_user_ids).and_return(vlj_user_ids)
        allow(non_legacy_docket).to receive(:tied_to_vljs).with(vlj_user_ids).and_return(tied_appeals)
        allow(described_class).to receive(:ama_rows).with(tied_appeals, :other).and_return(ama_rows)
      end

      it "processes non-legacy dockets correctly" do
        expect(described_class.tied_appeals).to eq(ama_rows)
      end
    end

    context "when there are multiple dockets with mixed types" do
      let(:legacy_docket) { instance_double("LegacyDocket") }
      let(:non_legacy_docket) { instance_double("DirectReviewDocket") }
      let(:legacy_appeals) { [{ docket_number: "123" }] }
      let(:non_legacy_appeals) { [{ docket_number: "789" }] }
      let(:unique_legacy_appeals) { [{ docket_number: "123" }] }
      let(:ama_rows) { [{ docket_number: "789" }] }

      before do
        dockets[:legacy] = legacy_docket
        dockets[:other] = non_legacy_docket
        allow(legacy_docket).to receive(:appeals_tied_to_avljs_and_vljs).and_return(legacy_appeals)
        allow(described_class).to receive(:legacy_rows).with(legacy_appeals, :legacy).and_return(unique_legacy_appeals)
        allow(non_legacy_docket).to receive(:tied_to_vljs).with(vlj_user_ids).and_return(non_legacy_appeals)
        allow(described_class).to receive(:ama_rows).with(non_legacy_appeals, :other).and_return(ama_rows)
      end

      it "returns combined results from different docket types" do
        expect(described_class.tied_appeals).to eq(unique_legacy_appeals + ama_rows)
      end
    end
  end
end
