# frozen_string_literal: true

require "./app/queries/appeals_in_location_63_in_past_2_days"

describe AppealsInLocation63InPast2Days do
  let(:job) { described_class }
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

  describe ".loc_63_appeals" do
    let(:non_ssc_avlj1) do
      User.find_by_css_id("NONSSCTST1") ||
        create(:user, :non_ssc_avlj_user, css_id: "NONSSCTST1", full_name: "First AVLJ")
    end

    let(:non_ssc_avlj2) do
      User.find_by_css_id("NONSSCTST2") ||
        create(:user, :non_ssc_avlj_user, css_id: "NONSSCTST2", full_name: "Second AVLJ")
    end
    let(:veteran) { create(:veteran) }

    let(:correspondent) do
      create(
        :correspondent,
        snamef: veteran.first_name,
        snamel: veteran.last_name,
        ssalut: "", ssn: veteran.file_number
      )
    end

    let(:vacols_prio_case) do
      create(
        :case,
        :aod,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: non_ssc_avlj1,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: 60.days.ago
      )
    end

    let(:vacols_non_prio_case) do
      create(
        :case,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: non_ssc_avlj2,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: 7.days.ago
      )
    end

    let!(:legacy_unsigned_priority_tied_to_non_ssc_avlj1) do
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_prio_case,
        closest_regional_office: "RO17"
      )
      create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
    end

    let!(:legacy_unsigned_non_priority_tied_to_non_ssc_avlj2) do
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_non_prio_case,
        closest_regional_office: "RO17"
      )
      create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
    end

    let!(:legacy_signed_non_priority_tied_to_non_ssc_avlj1) do
      create(:legacy_signed_appeal, :type_original, signing_avlj: non_ssc_avlj, assigned_avlj: non_ssc_avlj)
    end

    let!(:legacy_signed_priority_tied_to_non_ssc_avlj2) do
      create(:legacy_signed_appeal, :type_cavc_remand, signing_avlj: non_ssc_avlj2, assigned_avlj: non_ssc_avlj2)
    end

    let(:appeals) { [] }

    context "there are 2 appeals still in loc 81" do
      let(:vacols_prio_case_81) do
        create(
          :case,
          :aod,
          :tied_to_judge,
          :video_hearing_requested,
          :type_original,
          :ready_for_distribution,
          tied_judge: non_ssc_avlj1,
          correspondent: correspondent,
          bfcorlid: "#{veteran.file_number}S",
          case_issues: create_list(:case_issue, 3, :compensation),
          bfd19: 60.days.ago
        )
      end

      let(:vacols_non_prio_case_81) do
        create(
          :case,
          :tied_to_judge,
          :video_hearing_requested,
          :type_original,
          :ready_for_distribution,
          tied_judge: non_ssc_avlj2,
          correspondent: correspondent,
          bfcorlid: "#{veteran.file_number}S",
          case_issues: create_list(:case_issue, 3, :compensation),
          bfd19: 7.days.ago
        )
      end

      let!(:legacy_unsigned_priority_tied_to_non_ssc_avlj1_81) do
        legacy_appeal = create(
          :legacy_appeal,
          :with_root_task,
          vacols_case: vacols_prio_case_81,
          closest_regional_office: "RO17"
        )
        create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
      end

      let!(:legacy_unsigned_non_priority_tied_to_non_ssc_avlj2_81) do
        legacy_appeal = create(
          :legacy_appeal,
          :with_root_task,
          vacols_case: vacols_non_prio_case_81,
          closest_regional_office: "RO17"
        )
        create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
      end

      it "fetches the correct matching appeals only in loc 63" do
        move_to_loc_63(vacols_prio_case, 0.days.ago)
        move_to_loc_63(vacols_non_prio_case, 1.day.ago)
        move_to_loc_63(legacy_signed_non_priority_tied_to_non_ssc_avlj1, 1.day.ago)
        move_to_loc_63(legacy_signed_priority_tied_to_non_ssc_avlj2, 2.days.ago)

        expected_appeals = [
          vacols_prio_case,
          vacols_non_prio_case,
          legacy_signed_non_priority_tied_to_non_ssc_avlj1,
          legacy_signed_priority_tied_to_non_ssc_avlj2
        ]
        expected_appeals_appended_bfkeys = expected_appeals.map { |ea| "150000#{ea.bfkey}" }
        returned_appeals = job.send(:loc_63_appeals)

        # The expectation changes based on the current time in UTC.
        # Query method that retrieves the actual count from the database
        # If the current time is between 9 PM and 1 AM UTC,
        # the expectation is set to 3. Otherwise, it is set to 4.

        current_hour = Time.now.utc.hour
        hours = Time.now.utc.dst? ? [0, 1, 2] : [0, 1, 2, 3]
        expected_count = hours.include?(current_hour) ? 3 : 4
        expected_appeals_appended_bfkeys.pop if hours.include?(current_hour)

        expect(returned_appeals.size).to eq(expected_count)
        expect(returned_appeals.map { |ra| ra[:docket_number] }).to match_array(expected_appeals_appended_bfkeys)
      end
    end

    context "there are 2 appeals still in loc 81" do
      let(:vacols_prio_case_3_days) do
        create(
          :case,
          :aod,
          :tied_to_judge,
          :video_hearing_requested,
          :type_original,
          :ready_for_distribution,
          tied_judge: non_ssc_avlj1,
          correspondent: correspondent,
          bfcorlid: "#{veteran.file_number}S",
          case_issues: create_list(:case_issue, 3, :compensation),
          bfd19: 60.days.ago
        )
      end

      let(:vacols_non_prio_case_90_days) do
        create(
          :case,
          :tied_to_judge,
          :video_hearing_requested,
          :type_original,
          :ready_for_distribution,
          tied_judge: non_ssc_avlj2,
          correspondent: correspondent,
          bfcorlid: "#{veteran.file_number}S",
          case_issues: create_list(:case_issue, 3, :compensation),
          bfd19: 7.days.ago
        )
      end

      let!(:legacy_unsigned_priority_tied_to_non_ssc_avlj1_3_days) do
        legacy_appeal = create(
          :legacy_appeal,
          :with_root_task,
          vacols_case: vacols_prio_case_3_days,
          closest_regional_office: "RO17"
        )
        create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
      end

      let!(:legacy_unsigned_non_priority_tied_to_non_ssc_avlj2_90_days) do
        legacy_appeal = create(
          :legacy_appeal,
          :with_root_task,
          vacols_case: vacols_non_prio_case_90_days,
          closest_regional_office: "RO17"
        )
        create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
      end

      it "fetches the correct matching appeals only in loc 63" do
        move_to_loc_63(vacols_prio_case, 0.days.ago)
        move_to_loc_63(vacols_non_prio_case, 1.day.ago)
        move_to_loc_63(legacy_signed_non_priority_tied_to_non_ssc_avlj1, 1.day.ago)
        move_to_loc_63(legacy_signed_priority_tied_to_non_ssc_avlj2, 2.days.ago)
        move_to_loc_63(vacols_prio_case_3_days, 3.days.ago)
        move_to_loc_63(vacols_non_prio_case_90_days, 90.days.ago)

        expected_appeals = [
          vacols_prio_case,
          vacols_non_prio_case,
          legacy_signed_non_priority_tied_to_non_ssc_avlj1,
          legacy_signed_priority_tied_to_non_ssc_avlj2
        ]
        expected_appeals_appended_bfkeys = expected_appeals.map { |ea| "150000#{ea.bfkey}" }
        returned_appeals = job.send(:loc_63_appeals)

        # The expectation changes based on the current time in UTC.
        # Query method that retrieves the actual count from the database
        # If the current time is between 9 PM and 1 AM UTC,
        # the expectation is set to 3. Otherwise, it is set to 4.

        current_hour = Time.now.utc.hour
        hours = Time.now.utc.dst? ? [0, 1, 2] : [0, 1, 2, 3]
        expected_count = hours.include?(current_hour) ? 3 : 4
        expected_appeals_appended_bfkeys.pop if hours.include?(current_hour)

        expect(returned_appeals.size).to eq(expected_count)
        expect(returned_appeals.map { |ra| ra[:docket_number] }).to match_array(expected_appeals_appended_bfkeys)
      end
    end
  end

  def move_to_loc_63(legacy_case, date)
    value = date.in_time_zone("America/New_York")
    date_time = Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)

    legacy_case.update!(bfcurloc: 63, bfdlocin: date_time)
  end
end
