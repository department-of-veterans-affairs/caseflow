describe PowerOfAttorneyRepository do
  context ".get_vacols_rep_code" do
    subject { PowerOfAttorney.repository.get_vacols_rep_code(short_name) }

    context "returns the VACOLS code when it exists" do
      let(:name) { "American Legion" }
      it { is_expected.to eq("A") }
    end

    context "returns nil when it does not exist" do
      let(:name) { "Not an entry in the array" }
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

  context ".get_address_one_and_two" do
    subject { PowerOfAttorney.repository.get_address_one_and_two(representative_name, address) }

    context "when representative is a person" do
      let(:representative_name) { "Jack Kidwell" }
      let(:address) do
        {
          address_line_1: "122 Mullberry St.",
          address_line_2: "PO BOX 123",
          address_line_3: "Daisies",
          city: "Arlington",
          state: "VA",
          zip: "22202"
        }
      end

      it "should contain correct info in address_one and address_two" do
        address_one, address_two = subject
        expect(address_one).to eq "122 Mullberry St."
        expect(address_two).to eq "PO BOX 123 Daisies"
      end
    end

    context "when representative is not a person" do
      let(:representative_name) { "Services" }
      let(:address) do
        {
          address_line_1: nil,
          address_line_2: nil,
          address_line_3: nil,
          city: nil,
          state: nil,
          zip: nil
        }
      end

      it "should contain correct info in address_one and address_two" do
        address_one, address_two = subject
        expect(address_one).to eq "Services"
        expect(address_two).to eq ""
      end
    end

    context "when address is empty" do
      let(:representative_name) { "Jack Kidwell" }
      let(:address) do
        {
          address_line_1: nil,
          address_line_2: nil,
          address_line_3: nil,
          city: nil,
          state: nil,
          zip: nil
        }
      end

      it "should contain correct info in address_one and address_two" do
        address_one, address_two = subject
        expect(address_one).to eq ""
        expect(address_two).to eq ""
      end
    end
  end

  context ".update_vacols_rep_table!" do
    before do
      allow(Fakes::PowerOfAttorneyRepository).to receive(:update_vacols_rep_name!).and_call_original
      allow(Fakes::PowerOfAttorneyRepository).to receive(:update_vacols_rep_address!).and_call_original
    end

    context "when representative is not a person" do
      before do
        PowerOfAttorney.repository.update_vacols_rep_table!(
          appeal: Appeal.new(vacols_id: "123C"),
          representative_name: "This is not a name!",
          address: {
            address_line_1: "122 Mullberry St.",
            address_line_2: "PO BOX 123",
            address_line_3: "Daisies",
            city: "Arlington",
            state: "VA",
            zip: "22202"
          }
        )
      end
      it "calls update_vacols_rep_address with the correct arguments" do
        expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_address!).with(
          case_record: nil,
          address: {
            address_one: "This is not a name!",
            address_two: "122 Mullberry St. PO BOX 123 Daisies",
            city: "Arlington",
            state: "VA",
            zip: "22202"
          }
        )
      end

      it "calls update_vacols_rep_name with the correct arguments" do
        expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_name!).with(
          case_record: nil,
          first_name: "",
          middle_initial: "",
          last_name: ""
        )
      end
    end

    context "when representative is a person" do
      before do
        PowerOfAttorney.repository.update_vacols_rep_table!(
          appeal: Appeal.new(vacols_id: "123C"),
          representative_name: "Jane M Smith",
          address: {
            address_line_1: "122 Mullberry St.",
            address_line_2: "PO BOX 123",
            address_line_3: "Daisies",
            city: "Arlington",
            state: "VA",
            zip: "22202"
          }
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

      it "calls update_vacols_rep_address with the correct arguments" do
        expect(Fakes::PowerOfAttorneyRepository).to have_received(:update_vacols_rep_address!).with(
          case_record: nil,
          address: {
            address_one: "122 Mullberry St.",
            address_two: "PO BOX 123 Daisies",
            city: "Arlington",
            state: "VA",
            zip: "22202"
          }
        )
      end
    end
  end
end
