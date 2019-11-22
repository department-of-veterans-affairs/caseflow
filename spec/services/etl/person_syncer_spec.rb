# frozen_string_literal: true

describe ETL::PersonSyncer, :etl do
  describe "#call" do
    context "2 person records, one needing sync" do
      let!(:person1) { create(:person, updated_at: 3.days.ago) }
      let!(:person2) { create(:person) }

      subject { described_class.new(since: 2.days.ago).call }

      it "syncs 1 person record" do
        expect(ETL::Person.all.count).to eq(0)
        subject
        expect(ETL::Person.all.count).to eq(1)
        expect(ETL::Person.first.attributes).to eq(person2.attributes)
      end
    end
  end
end
