# frozen_string_literal: true

require "rails_helper"

describe RegionalOffice do
  let(:regional_office) { RegionalOffice.new(regional_office_key) }
  let(:regional_office_key) { nil }

  context ".find!" do
    subject { RegionalOffice.find!(regional_office_key) }

    context "valid regional office key" do
      let(:regional_office_key) { "RO43" }

      it do
        is_expected.to have_attributes(
          key: "RO43",
          station_key: "343",
          city: "Oakland",
          state: "CA",
          valid?: true
        )
      end
    end

    context "valid satellite office key" do
      let(:regional_office_key) { "SO43" }

      it do
        is_expected.to have_attributes(
          key: "SO43",
          city: "Sacremento",
          state: "CA",
          valid?: true
        )
      end
    end

    context "invalid regional office key" do
      let(:regional_office_key) { "RO747" }

      it "raises NotFoundError" do
        expect { subject }.to raise_error(RegionalOffice::NotFoundError)
      end
    end
  end

  context ".for_station" do
    subject { RegionalOffice.for_station("311") }

    it "returns regional office objects for each RO in the station" do
      expect(subject.length).to eq(2)
      expect(subject.first).to have_attributes(key: "RO11", city: "Pittsburgh")
      expect(subject.last).to have_attributes(key: "RO71", city: "Pittsburgh Foreign Cases")
    end
  end
end
