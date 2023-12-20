# frozen_string_literal: true

describe AppealHearingSerializer, :all_dbs do
  let(:hearing) { create(:hearing) }
  let(:user) { create(:user) }

  subject { described_class.new(hearing, params: { user: user }) }

  context "when a user views hearing information" do
    context "when user has a VSO role" do
      let(:user) { create(:user, :vso_role) }
      it "does not display judge name" do
        expect(subject.serializable_hash[:data][:attributes][:held_by]).to be_nil
      end
    end

    context "when user does not have a VSO role" do
      it "does display judge name" do
        expect(subject.serializable_hash[:data][:attributes][:held_by]).to eq(hearing.judge.full_name)
      end
    end
  end

  context "when the associated hearing_day has been soft-deleted" do
    before do
      hearing.hearing_day.update!(deleted_at: Time.zone.today - 90.days)
      hearing.reload
    end

    it "returns nil for values that we would retrieve from hearing_day" do
      expect(subject.serializable_hash[:data][:attributes][:date]).to be_nil
      expect(subject.serializable_hash[:data][:attributes][:type]).to be_nil
    end
  end
end
