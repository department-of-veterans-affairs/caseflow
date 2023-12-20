# frozen_string_literal: true

describe ETL::UserSyncer, :etl do
  describe "#call" do
    let!(:vacols_user1) { create(:staff, :judge_role) }
    let!(:vacols_user2) { create(:staff, :attorney_judge_role) }
    let!(:user1) { create(:user, css_id: vacols_user1.sdomainid) }
    let!(:user2) { create(:user, css_id: vacols_user2.sdomainid, updated_at: 3.days.ago.round) }
    let!(:user3) { create(:user) }
    let(:etl_build) { ETL::Build.create }

    before do
      Timecop.travel(3.days.ago.round) do
        CachedUser.sync_from_vacols
      end
    end

    context "3 User records, 2 needing sync" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      it "syncs 2 records" do
        expect(ETL::User.all.count).to eq(0)

        subject

        expect(ETL::User.all.count).to eq(2)
        expect(ETL::User.find_by(user_id: user1.id)).to_not be_nil
        expect(ETL::User.find_by(user_id: user1.id).sactive).to eq "A"

        expect(ETL::User.find_by(user_id: user3.id)).to_not be_nil
        expect(ETL::User.find_by(user_id: user3.id).sactive).to be_nil
      end
    end

    context "VACOLS attribute changes" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      before do
        described_class.new(etl_build: etl_build).call
        user2.vacols_user.svlj = "J"
        user2.vacols_user.save!
      end

      it "detects User should sync" do
        expect(ETL::User.all.count).to eq(3)
        expect(ETL::User.find_by(user_id: user2.id).svlj).to eq "A"

        subject

        expect(ETL::User.find_by(user_id: user2.id).svlj).to eq "J"
      end
    end

    context "3 User records, full sync" do
      subject { described_class.new(etl_build: etl_build).call }

      it "syncs all records" do
        expect(ETL::User.all.count).to eq(0)

        subject
        expect(ETL::User.find_by(user_id: user1.id).svlj).to eq "J"
        expect(ETL::User.find_by(user_id: user1.id).sattyid).to eq user1.vacols_user.sattyid
        expect(ETL::User.find_by(user_id: user2.id).svlj).to eq "A"
        expect(ETL::User.find_by(user_id: user2.id).sattyid).to eq user2.vacols_user.sattyid

        expect(ETL::User.all.count).to eq(3)
      end
    end

    context "origin User record changes" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      before do
        described_class.new(etl_build: etl_build).call
      end

      let(:new_name) { "foobar" }

      it "updates attributes" do
        expect(user2.full_name).to_not eq(new_name)
        expect(ETL::User.find_by(user_id: user2.id).full_name).to_not eq(new_name)
        expect(ETL::User.all.count).to eq(3)

        user2.update!(full_name: new_name)
        subject

        expect(ETL::User.find_by(user_id: user2.id).full_name).to eq(new_name)
      end
    end
  end
end
