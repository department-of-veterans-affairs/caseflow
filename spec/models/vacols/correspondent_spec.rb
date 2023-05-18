# frozen_string_literal: true

describe VACOLS::Correspondent do
  describe "updating veteran NOD in VACOLS" do
    let(:good_veteran) { { veterans_ssn: "123456789", deceased_time: "20111012" } }
    let(:good_veteran_different_deceased_time) { { veterans_ssn: "333333333", deceased_time: "20001111" } }
    let(:veteran_nil_deceased_time) { { veterans_ssn: "123456789", deceased_time: nil } }
    let(:veteran_not_in_vacols) { { veterans_pat: "BADKEY1", veterans_ssn: "000000000", deceased_time: "20111012" } }
    let(:veteran_ssn_multiple_matches) { { veterans_ssn: "111111111", deceased_time: "20111012" } }
    # deceased_time for this case needs to be 1.day.ago because the factorybot create method
    # in the before block doesn't translate the date format correctly
    let(:veteran_deceased_time_matches_input) { { veterans_ssn: "222222222", deceased_time: 1.day.ago } }
    let(:good_veteran_using_pat) do
      { veterans_pat: "STAFKEY1", veterans_ssn: "444444444", deceased_time: "20111012" }
    end
    let(:good_veteran_using_pat_different_deceased_time) do
      { veterans_pat: "STAFKEY2", veterans_ssn: "555555555", deceased_time: "20001111" }
    end

    before do
      create(:correspondent, ssn: "123456789")
      create(:correspondent, ssn: "222222222", sfnod: 1.day.ago)
      create(:correspondent, ssn: "333333333", sfnod: "11-NOV-01")
      2.times do
        create(:correspondent, ssn: "111111111")
      end
      create(:correspondent, stafkey: good_veteran_using_pat[:veterans_pat])
      create(:correspondent,
             stafkey: good_veteran_using_pat_different_deceased_time[:veterans_pat],
             sfnod: "11-NOV-01")
      allow(Rails.logger).to receive(:info).at_least(:once)
    end

    context "with bad inputs:" do
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

      it "multiple veterans found with the same SSN" do
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
      it "using SSN, veteran has deceased time that differs from input" do
        described_class.update_veteran_nod(good_veteran_different_deceased_time)
        updated_vet = described_class.find_by(ssn: good_veteran_different_deceased_time[:veterans_ssn])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran_different_deceased_time[:deceased_time].to_date)
      end

      it "using SSN, veteran has no recorded deceased time" do
        described_class.update_veteran_nod(good_veteran)
        updated_vet = described_class.find_by(ssn: good_veteran[:veterans_ssn])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran[:deceased_time].to_date)
      end

      it "using PAT, veteran has deceased time that differs from input" do
        described_class.update_veteran_nod(good_veteran_using_pat_different_deceased_time)
        updated_vet = described_class.find(good_veteran_using_pat_different_deceased_time[:veterans_pat])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran_using_pat_different_deceased_time[:deceased_time].to_date)
      end

      it "using PAT, veteran has no recorded deceased time" do
        described_class.update_veteran_nod(good_veteran_using_pat)
        updated_vet = described_class.find(good_veteran_using_pat[:veterans_pat])
        expect(updated_vet.sfnod.to_date).to eq(good_veteran_using_pat[:deceased_time].to_date)
      end
    end
  end
end
