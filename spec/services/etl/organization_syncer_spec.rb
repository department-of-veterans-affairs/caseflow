# frozen_string_literal: true

describe ETL::OrganizationSyncer, :etl do
  describe "#call" do
    context "2 org records, one needing sync" do
      let!(:org1) { create(:organization, updated_at: 3.days.ago) }
      let!(:org2) { create(:organization) }

      subject { described_class.new(since: 2.days.ago).call }

      it "syncs 1 record" do
        expect(ETL::Organization.all.count).to eq(0)
        subject
        expect(ETL::Organization.all.count).to eq(1)
        expect(ETL::Organization.first.attributes).to eq(org2.attributes)
      end
    end
  end
end
