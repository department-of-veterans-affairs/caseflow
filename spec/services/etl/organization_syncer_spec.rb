# frozen_string_literal: true

describe ETL::OrganizationSyncer, :etl do
  describe "#call" do
    let!(:org1) { create(:organization, updated_at: 3.days.ago.round) }
    let!(:org2) { create(:organization) }
    let(:etl_build) { ETL::Build.create }

    context "2 org records, one needing sync" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      it "syncs 1 record" do
        expect(ETL::Organization.all.count).to eq(0)

        subject

        expect(ETL::Organization.all.count).to eq(1)
        expect(ETL::Organization.first.name).to eq(org2.name)
      end
    end

    context "2 org records, full sync" do
      subject { described_class.new(etl_build: etl_build).call }

      it "syncs all records" do
        expect(ETL::Organization.all.count).to eq(0)

        subject

        expect(ETL::Organization.all.count).to eq(2)
      end
    end

    context "origin Org record changes" do
      subject { described_class.new(since: 2.days.ago.round, etl_build: etl_build).call }

      before do
        described_class.new(etl_build: etl_build).call
      end

      let(:new_name) { "foobar" }

      it "updates attributes" do
        expect(org2.name).to_not eq(new_name)
        expect(ETL::Organization.find(org2.id).name).to_not eq(new_name)
        expect(ETL::Organization.all.count).to eq(2)

        org2.update!(name: new_name)
        subject

        expect(ETL::Organization.find(org2.id).name).to eq(new_name)
      end
    end
  end
end
