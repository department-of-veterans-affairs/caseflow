# frozen_string_literal: true

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

  context ".city_state_by_key" do
    let(:key) { "RO01" }

    subject { RegionalOffice.city_state_by_key(key) }

    context "invalid key" do
      let(:key) { "RO10000" }

      it "is nil" do
        expect(subject).to eq nil
      end
    end

    context "valid key" do
      it "returns the correct city and state" do
        expect(subject).to eq "Boston, MA"
      end
    end
  end

  context ".valid?" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) is valid?" do
        expect(ro.valid?).to eq true
      end
    end
  end

  context ".facility_id" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) does not throw when facility id is called" do
        expect { ro.facility_id }.not_to raise_error
      end
    end
  end

  context ".ro_facility_ids" do
    subject { RegionalOffice.ro_facility_ids }

    it "returns all RO facility ids" do
      expect(subject.count).to eq 57
    end
  end

  context ".ro_facility_ids_for_state for TX" do
    subject { RegionalOffice.ro_facility_ids_for_state("TX") }

    it "returns ro facility ids for Texas" do
      expect(subject).to match_array(%w[vba_349 vba_362])
    end
  end

  context ".street_address" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) does not throw when street_address is called" do
        expect { ro.street_address }.not_to raise_error
      end
    end

    it "RO87 has nil address" do
      ro = RegionalOffice.find!("RO87")

      expect(ro.street_address).to eq nil
    end

    it "RO46 has correct address" do
      ro = RegionalOffice.find!("RO46")

      expect(ro.street_address).to eq "915 Second Avenue"
    end
  end

  context ".full_address" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) does not throw when full_address is called" do
        expect { ro.full_address }.not_to raise_error
      end
    end

    it "RO87 has nil address" do
      ro = RegionalOffice.find!("RO87")

      expect(ro.full_address).to eq nil
    end

    it "RO55 has correct address" do
      ro = RegionalOffice.find!("RO55")

      expect(ro.full_address).to eq "50 Carr 165, San Juan PR 00968"
    end

    it "RO50 has correct address" do
      ro = RegionalOffice.find!("RO50")

      expect(ro.full_address).to eq "2200 Fort Roots Drive Bldg. 65, Little Rock AR 72114"
    end
  end

  context ".name" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) does not throw when name is called" do
        expect { ro.name }.not_to raise_error
      end
    end
  end

  context ".zip_code" do
    RegionalOffice.all.each do |ro|
      it "regional office (#{ro.key}) does not throw when zip_code is called" do
        expect { ro.zip_code }.not_to raise_error
      end
    end
  end
end
