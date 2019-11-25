# frozen_string_literal: true

describe ETL::UserSyncer, :etl do
  describe "#call" do
    let!(:vacols_user1) { create(:staff, :judge_role) }
    let!(:vacols_user2) { create(:staff, :attorney_judge_role) }
    let!(:user1) { create(:user, css_id: vacols_user1.sdomainid) }
    let!(:user2) { create(:user, css_id: vacols_user2.sdomainid, updated_at: 3.days.ago) }

    before do
      Timecop.travel(3.days.ago) do
        CachedUser.sync_from_vacols
      end
    end

    context "2 User records, 1 needing sync" do
      subject { described_class.new(since: 2.days.ago).call }

      it "syncs 1 record" do
        expect(ETL::User.all.count).to eq(0)

        subject

        expect(ETL::User.all.count).to eq(1)
        expect(ETL::User.first.css_id).to eq(user1.css_id)
      end
    end

    context "VACOLS attribute changes" do
      subject { described_class.new(since: 2.days.ago).call }

      before do
        described_class.new.call
        user2.vacols_user.svlj = "J"
        user2.vacols_user.save!
      end

      it "detects User should sync" do
        expect(ETL::User.all.count).to eq(2)
        expect(ETL::User.find_by(user_id: user2.id).svlj).to eq "A"

        subject

        expect(ETL::User.find_by(user_id: user2.id).svlj).to eq "J"
      end
    end

    context "2 org records, full sync" do
      subject { described_class.new.call }

      it "syncs all records" do
        expect(ETL::User.all.count).to eq(0)

        subject

        expect(ETL::User.all.count).to eq(2)
      end
    end

    context "origin User record changes" do
      subject { described_class.new(since: 2.days.ago).call }

      before do
        described_class.new.call
      end

      let(:new_name) { "foobar" }

      it "updates attributes" do
        expect(user2.full_name).to_not eq(new_name)
        expect(ETL::User.find_by(user_id: user2.id).full_name).to_not eq(new_name)
        expect(ETL::User.all.count).to eq(2)

        user2.update!(full_name: new_name)
        subject

        expect(ETL::User.find_by(user_id: user2.id).full_name).to eq(new_name)
      end
    end
  end
end
