describe PowerOfAttorneyRepository do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
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
    context "when representative is not a person" do
      let(:vacols_case) { create(:case, bfkey: "123C") }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

      before do
        PowerOfAttorney.repository.update_vacols_rep_table!(
          appeal: appeal,
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

      it "sets the values in VACOLS" do
        vacols_case.representative.reload
        expect(vacols_case.representative.repfirst).to eq(nil)
        expect(vacols_case.representative.repmi).to eq(nil)
        expect(vacols_case.representative.replast).to eq(nil)
        expect(vacols_case.representative.repaddr1).to eq("This is not a name!")
        expect(vacols_case.representative.repaddr2).to eq("122 Mullberry St. PO BOX 123 Daisies")
        expect(vacols_case.representative.repcity).to eq("Arlington")
        expect(vacols_case.representative.repst).to eq("VA")
        expect(vacols_case.representative.repzip).to eq("22202")
      end
    end

    context "when representative is a person" do
      let(:vacols_case) { create(:case) }
      let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

      before do
        PowerOfAttorney.repository.update_vacols_rep_table!(
          appeal: appeal,
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

      it "sets the values in VACOLS" do
        vacols_case.representative.reload
        expect(vacols_case.representative.repfirst).to eq("Jane")
        expect(vacols_case.representative.repmi).to eq("M")
        expect(vacols_case.representative.replast).to eq("Smith")
        expect(vacols_case.representative.repaddr1).to eq("122 Mullberry St.")
        expect(vacols_case.representative.repaddr2).to eq("PO BOX 123 Daisies")
        expect(vacols_case.representative.repcity).to eq("Arlington")
        expect(vacols_case.representative.repst).to eq("VA")
        expect(vacols_case.representative.repzip).to eq("22202")
      end
    end
  end
end
