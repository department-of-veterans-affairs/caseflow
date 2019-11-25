# frozen_string_literal: true

describe ETL::PersonSyncer, :etl do
  describe "#call" do
    let!(:person1) { create(:person, updated_at: 3.days.ago) }
    let!(:person2) { create(:person) }

    context "2 person records, one needing sync" do
      subject { described_class.new(since: 2.days.ago).call }

      it "syncs 1 record" do
        expect(ETL::Person.all.count).to eq(0)

        subject

        expect(ETL::Person.all.count).to eq(1)
        expect(ETL::Person.first.id).to eq(person2.id)
      end
    end

    context "2 person records, full sync" do
      subject { described_class.new.call }

      it "syncs all records" do
        expect(ETL::Person.all.count).to eq(0)

        subject

        expect(ETL::Person.all.count).to eq(2)
      end
    end

    context "origin Person record changes" do
      subject { described_class.new(since: 2.days.ago).call }

      before do
        described_class.new.call
      end

      let(:new_last_name) { "foobar" }

      it "updates attributes" do
        expect(person2.last_name).to_not eq(new_last_name)
        expect(ETL::Person.find(person2.id).first_name).to_not eq(new_last_name)
        expect(ETL::Person.all.count).to eq(2)

        person2.update!(last_name: new_last_name)
        subject

        expect(ETL::Person.find(person2.id).last_name).to eq(new_last_name)
      end
    end
  end
end
