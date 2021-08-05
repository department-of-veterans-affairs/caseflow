# frozen_string_literal: true

describe AppealHearingSerializer, :all_dbs do
  context "when a user views hearing information" do
    let(:hearing) { create(:hearing) }
    subject { described_class.new(hearing) }

    it "does not display judge name" do
      expect(subject.serializable_hash[:data][:attributes][:held_by]).to be_nil
    end
  end
end
