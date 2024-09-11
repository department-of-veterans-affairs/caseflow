# frozen_string_literal: true

require "./app/queries/appeals_in_location_63_in_past_2_days"

describe AppealsInLocation63InPast2Days do
  let(:avlj_name) { "Avlj Judge" }
  let(:avlj_fname) { "Avlj" }
  let(:avlj_lname) { "Judge" }

  let(:non_ssc_avlj) do
    User.find_by_css_id("NONSSCTEST") ||
      create(:user, :non_ssc_avlj_user, css_id: "NONSSCTEST", full_name: avlj_name)
  end

  let(:prev_deciding_judge) do
    User.find_by_css_id("PREDECJUDG") ||
      create(:user, :vlj_user, css_id: "PREDECJUDG", full_name: "Prevdec Judge")
  end

  let(:appeal) do
    {
      "tinum" => "150000999988855",
      "aod" => false,
      "cavc" => false,
      "bfd19" => "2023-01-05 00:00:00 UTC",
      "bfdloout" => "2024-08-27 09:19:55 UTC",
      "ssn" => "999559999",
      "snamef" => "Bob",
      "snamel" => "Goodman",
      "vlj" => non_ssc_avlj.vacols_staff.sattyid,
      "vlj_namef" => avlj_fname,
      "vlj_namel" => avlj_lname,
      "prev_deciding_judge" => prev_deciding_judge.vacols_staff.sattyid,
      "bfkey" => "99",
      "bfdlocin" => "2024-09-10 14:40:58 UTC",
      "bfcurloc" => "63"
    }
  end

  context "#process and #tied_appeals" do
    it "selects all appeals in location 63 and generates the CSV" do
      allow(AppealRepository).to receive(:loc_63_appeals).and_return([appeal])
      expect { described_class.process }.not_to raise_error
      expect(described_class.loc_63_appeals.size).to eq 1
    end
  end

  context "Test the CSV generation" do
    context "where it uses attributes " do
      it "to create a hash Legacy rows moved to loc 63" do
        subject_legacy = described_class.legacy_rows([appeal]).first

        expect(subject_legacy[:docket_number]).to eq appeal["tinum"]
        expect(subject_legacy[:aod]).to eq appeal["aod"]
        expect(subject_legacy[:cavc]).to be appeal["cavc"]
        expect(subject_legacy[:receipt_date]).to eq appeal["bfd19"]
        expect(subject_legacy[:ready_for_distribution_at]).to eq appeal["bfdloout"]
        expect(subject_legacy[:veteran_file_number]).to eq appeal["ssn"]
        expect(subject_legacy[:veteran_name]).to eq "Bob Goodman"
        expect(subject_legacy[:hearing_judge_id]).to eq non_ssc_avlj.vacols_staff.sdomainid
        expect(subject_legacy[:hearing_judge_name]).to eq avlj_name
        expect(subject_legacy[:deciding_judge_id]).to eq prev_deciding_judge.vacols_staff.sdomainid
        expect(subject_legacy[:deciding_judge_name]).to eq prev_deciding_judge.full_name
        expect(subject_legacy[:affinity_start_date]).to eq nil
        expect(subject_legacy[:moved_date_time]).to eq appeal["bfdlocin"]
        expect(subject_legacy[:bfcurloc]).to eq appeal["bfcurloc"]
      end
    end
  end
end
