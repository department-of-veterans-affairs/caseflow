describe PowerOfAttorneyRepository do
  context ".get_vacols_reptype_code" do
    subject { PowerOfAttorney.repository.get_vacols_reptype_code(short_name: short_name) }

    context "returns the VACOLS code when it exists" do
      let(:short_name) { "American Legion" }
      it { is_expected.to eq("A") }
    end

    context "returns nil when it does not exist" do
      let(:short_name) { "Not an entry in the array" }
      it { is_expected.to eq(nil) }
    end
  end

  context ".first_last_name?" do
    subject { PowerOfAttorney.repository.first_last_name?(representative_name: representative_name) }

    context "returns true for a first and last name" do
      let(:representative_name) { "Jane Smith" }
      it { is_expected.to eq(true) }
    end

    context "returns false if it is not a first and last name" do
      let(:representative_name) { "Not a first and last name" }
      it { is_expected.to eq(false) }
    end
  end

  context ".first_middle_last_name?" do
    subject { PowerOfAttorney.repository.first_middle_last_name?(representative_name: representative_name) }

    context "returns true for a first, middle initial, and last name" do
      let(:representative_name) { "Jane A. Smith" }
      it { is_expected.to eq(true) }
    end

    context "returns false if it is not a name" do
      let(:representative_name) { "Not a first and last name" }
      it { is_expected.to eq(false) }
    end
  end
end
