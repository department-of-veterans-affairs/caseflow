# frozen_string_literal: true

describe VACOLS::Correspondent do
  describe "updating veteran NOD in VACOLS" do
    let(:good_veteran) { { id: "123456789", deceased_ind: true, deceased_time: "20111012" } }
    let(:good_veteran_different_deceased_time) { { id: "333333333", deceased_ind: true, deceased_time: "20001111" } }
    let(:veteran_nil_deceased_ind) { { id: "123456789", deceased_ind: nil, deceased_time: "20111012" } }
    let(:veteran_nil_deceased_time) { { id: "123456789", deceased_ind: true, deceased_time: nil } }
    let(:veteran_not_in_vacols) { { id: "000000000", deceased_ind: true, deceased_time: "20111012" } }
    let(:veteran_ssn_multiple_matches) { { id: "111111111", deceased_ind: true, deceased_time: "20111012" } }
    # deceased_time for this case needs to be 1.day.ago because the factorybot create method
    # in the before block doesn't translate the date format correctly
    let(:veteran_deceased_time_matches_input) { { id: "222222222", deceased_ind: true, deceased_time: 1.day.ago } }

    before do
      create(:correspondent, ssn: "123456789")
      create(:correspondent, ssn: "222222222", sfnod: 1.day.ago)
      create(:correspondent, ssn: "333333333", sfnod: "11-NOV-01")
      2.times do
        create(:correspondent, ssn: "111111111")
      end

      allow(Rails.logger).to receive(:info).at_least(:once)
    end

    context "with bad inputs:" do
      it "nil deceased indicator" do
        described_class.update_veteran_nod(veteran_nil_deceased_ind)
        expect(Rails.logger).to have_received(:info).with("Veteran deceased indicator is false or null").once
      end

      it "nil deceased time" do
        described_class.update_veteran_nod(veteran_nil_deceased_time)
        expect(Rails.logger).to have_received(:info).with("No deceased time was provided").once
      end
    end

    context "with good inputs but should not update veteran:" do
      it "veteran not found in database" do
        described_class.update_veteran_nod(veteran_not_in_vacols)
        expect(Rails.logger).to have_received(:info).with("No veteran found with that identifier").once
      end

      it "multiple veterans found with the same ID" do
        described_class.update_veteran_nod(veteran_ssn_multiple_matches)
        expect(Rails.logger).to have_received(:info).with("Multiple veterans found with that identifier").once
      end

      it "veteran deceased time already matches input" do
        described_class.update_veteran_nod(veteran_deceased_time_matches_input)
        expect(Rails.logger)
          .to have_received(:info).with("Veteran is already recorded with that deceased time in VACOLS").once
      end
    end

    context "with good inputs and veteran should be updated:" do
      it "veteran has deceased time that differs from input" do
        described_class.update_veteran_nod(good_veteran_different_deceased_time)
        updated_vet = described_class.find_by(ssn: good_veteran_different_deceased_time[:id])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran_different_deceased_time[:deceased_time].to_date)
      end

      it "veteran has no recorded deceased time" do
        described_class.update_veteran_nod(good_veteran)
        updated_vet = described_class.find_by(ssn: good_veteran[:id])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran[:deceased_time].to_date)
      end
    end
  end
end
