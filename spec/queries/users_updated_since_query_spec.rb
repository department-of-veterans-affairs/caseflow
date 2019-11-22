# frozen_string_literal: true

describe UsersUpdatedSinceQuery, :all_dbs do
  before do
    Timecop.freeze(post_ama_start_date)
  end

  let(:since_date) { Time.zone.now }
  let(:old_user) { create(:user, updated_at: since_date - 1.hour) }

  describe "#call" do
    subject { described_class.new(since_date: since_date).call }

    context "User updated_at since" do
      let!(:user) { create(:user, updated_at: since_date + 1.hour) }

      it "returns 1 User" do
        expect(subject).to eq([user])
      end
    end

    context "CachedUser updated_at since" do
      let(:vacols_user) { create(:staff) }
      let!(:user) { create(:user, css_id: vacols_user.sdomainid, updated_at: since_date - 1.hour) }

      before do
        CachedUser.sync_from_vacols
      end

      it "returns 1 User" do
        expect(subject).to eq([user])
      end
    end
  end
end
