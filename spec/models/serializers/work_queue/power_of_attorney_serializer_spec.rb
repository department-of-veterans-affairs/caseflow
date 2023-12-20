# frozen_string_literal: true

describe WorkQueue::PowerOfAttorneySerializer, :postgres do
  let(:poa) { create(:bgs_power_of_attorney, poa_participant_id: "10001Dalmations") }
  subject { described_class.new(poa).serializable_hash[:data][:attributes] }

  describe "#as_json" do
    context "with an ihp-writing representative organization" do
      let!(:org) { create(:organization, type: "Vso", participant_id: "10001Dalmations") }

      it "allows ihp-writing tasks" do
        expect(subject[:ihp_allowed]).to be true
      end
    end

    context "with an non-ihp-writing representative organization" do
      let!(:org) { create(:organization, type: "FieldVso", participant_id: "10001Dalmations") }

      it "allows ihp-writing tasks" do
        expect(subject[:ihp_allowed]).to be false
      end
    end
  end
end
