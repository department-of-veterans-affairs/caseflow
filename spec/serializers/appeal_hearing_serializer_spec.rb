# frozen_string_literal: true

describe AppealHearingSerializer, :all_dbs do
  context "when a user views hearing information" do
    let(:hearing) { create(:hearing) }
    subject { described_class.new(hearing, params: { user: user }) }

    context "when user has a VSO role" do
      let(:user) { create(:user, :vso_role) }
      it "does not display judge name" do
        expect(subject.serializable_hash[:data][:attributes][:held_by]).to be_nil
      end
    end

    context "when user does not have a VSO role" do
      let(:user) { create(:user) }
      it "does display judge name" do
        expect(subject.serializable_hash[:data][:attributes][:held_by]).to eq(hearing.judge.full_name)
      end
    end
  end
end
