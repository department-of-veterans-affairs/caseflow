# frozen_string_literal: true

require "./app/queries/appeals_in_location_63_in_past_2_days"

describe AppealsInLocation63InPast2Days do
  let(:hearing_judge) { create(:user, :judge, :with_vacols_judge_record) }
  let(:original_deciding_judge) { create(:user, :judge, :with_vacols_judge_record) }

  avlj_name = "John Doe"
  prev_judge_name = "Jane Smith"
  let(:non_ssc_avlj) do
    User.find_by_css_id("NONSSCTEST") ||
      create(:user, :non_ssc_avlj_user, css_id: "NONSSCTEST", full_name: avlj_name)
  end

  signing_avlj_name = "Smith Money"
  let(:signing_avlj) do
    User.find_by_css_id("SAVLJTEST") ||
      create(:user, :non_ssc_avlj_user, css_id: "SAVLJTEST", full_name: signing_avlj_name)
  end

  context "#process and #tied_appeals" do
    let(:appeal) do
      {
        tinum: "150000999988855",
        aod: true,
        cavc: false,
        bfd19: "2023-01-05 00:00:00 UTC",
        bfdloout: "2024-08-27 09:19:55 UTC",
        ssn: "999559999",
        snamef: "Bob",
        snamel: "Goodman",
        vlj: avlj_name,
        vlj_namef: "John",
        vlj_namel: "Smith",
        prev_deciding_judge: prev_judge_name,
        bfkey: "99",
        bfdlocin: "2024-09-10 14:40:58 UTC",
        bfcurloc: "63"
      }
    end

    it "selects all appeals in location 63 and generates the CSV" do
      allow(AppealRepository).to receive(:loc_63_appeals).and_return([appeal])
      # allow(AppealAffinity).to receive(:find_by).and_return({ affinity_start_date: "2024-05-08 09:16:49 -0400" })
      expect { described_class.process }.not_to raise_error
      expect(described_class.loc_63_appeals.size).to eq 1
    end
  end
end
