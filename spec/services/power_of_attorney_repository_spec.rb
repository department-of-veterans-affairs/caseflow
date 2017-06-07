describe PowerOfAttorneyRepository do
  context ".get_vacols_rep_code" do
    subject { PowerOfAttorney.repository.get_vacols_rep_code(short_name) }

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
    subject { PowerOfAttorney.repository.first_last_name?(representative_name) }

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
    subject { PowerOfAttorney.repository.first_middle_last_name?(representative_name) }

    context "returns true for a first, middle initial, and last name" do
      let(:representative_name) { "Jane A. Smith" }
      it { is_expected.to eq(true) }
    end

    context "returns false if it is not a name" do
      let(:representative_name) { "Not a first and last name" }
      it { is_expected.to eq(false) }
    end
  end

  context ".update_vacols_rep_table!" do
    before do
      allow(Fakes::PowerOfAttorneyRepository).to receive(:update_vacols_rep_name!).and_call_original
      allow(Fakes::PowerOfAttorneyRepository).to receive(:update_vacols_rep_address_one!).and_call_original
      PowerOfAttorney.repository.update_vacols_rep_table!(
        appeal: Appeal.new(vacols_id: "123C"),
        representative_name: "Jane M Smith"
      )
      PowerOfAttorney.repository.update_vacols_rep_table!(
        appeal: Appeal.new(vacols_id: "123C"),
        representative_name: "This is not a name!"
      )
    end

    it "calls update_vacols_rep_name with the correct arguments" do
      expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_name!).with(
        case_record: nil,
        first_name: "Jane",
        middle_initial: "M",
        last_name: "Smith"
      )
    end

    it "calls update_vacols_rep_address_one with the correct arguments" do
      expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_address_one!).with(
        case_record: nil,
        address_one: "This is not a name!"
      )
    end
  end
end
