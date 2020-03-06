# frozen_string_literal: true

describe ETL::OrganizationsUserSyncer, :etl do
  describe "#call" do
    let!(:org_user1) { create(:organizations_user, user: user, organization: org1) }
    let!(:org_user2) { create(:organizations_user, user: user, organization: org2, updated_at: 3.days.ago.round) }
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }
    let(:user) { create(:user) }
    let(:etl_build) { ETL::Build.create }

    context "2 org_user records, one needing sync" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      it "syncs 1 record" do
        expect(ETL::OrganizationsUser.all.count).to eq(0)

        subject

        expect(ETL::OrganizationsUser.all.count).to eq(1)
        expect(ETL::OrganizationsUser.first.id).to eq(org_user1.id)
      end
    end

    context "2 org records, full sync" do
      subject { described_class.new(etl_build: etl_build).call }

      it "syncs all records" do
        expect(ETL::OrganizationsUser.all.count).to eq(0)

        subject

        expect(ETL::OrganizationsUser.all.count).to eq(2)
      end
    end

    context "origin record changes" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      before do
        described_class.new(etl_build: etl_build).call
      end

      let(:new_admin) { true }

      it "updates attributes" do
        expect(org_user2.admin).to_not eq(new_admin)
        expect(ETL::OrganizationsUser.find(org_user2.id).admin).to_not eq(new_admin)
        expect(ETL::OrganizationsUser.all.count).to eq(2)

        org_user2.update!(admin: new_admin)
        subject

        expect(ETL::OrganizationsUser.find(org_user2.id).admin).to eq(new_admin)
      end
    end
  end
end
