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

  context ".facility_ids" do
    subject { RegionalOffice.facility_ids }

    it "returns all RO and AHL facility ids" do
      expect(subject.count).to eq 142
    end
  end

  context ".ro_facility_ids" do
    subject { RegionalOffice.ro_facility_ids }

    it "returns all RO facility ids" do
      expect(subject.count).to eq 58
    end
  end

  context ".ro_facility_ids_for_state for TX" do
    subject { RegionalOffice.ro_facility_ids_for_state("TX") }

    it "returns ro facility ids for Texas" do
      expect(subject).to match_array(%w[vba_349 vba_362])
    end
  end

  context ".find_ro_by_facility_id" do
    let(:ro_facility_id) { "vba_377" }
    let(:ahl_facility_id) { "vba_405" }

    it "returns RO ids for either RO or AHL facility ids" do
      expect(RegionalOffice.find_ro_by_facility_id(ro_facility_id)).to eq "RO77"
      expect(RegionalOffice.find_ro_by_facility_id(ahl_facility_id)).to eq "RO05"
    end
  end
end
