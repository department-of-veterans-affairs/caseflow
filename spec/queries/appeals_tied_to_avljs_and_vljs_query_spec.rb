# frozen_string_literal: true

describe AppealsTiedToAvljsAndVljsQuery do
  let(:hearing_judge) { create(:user, :judge, :with_vacols_judge_record) }
  let(:original_deciding_judge) { create(:user, :judge, :with_vacols_judge_record) }

  avlj_name = "John Doe"
  let(:non_ssc_avlj) do
    User.find_by_css_id("NONSSCTEST") ||
      create(:user, :non_ssc_avlj_user, css_id: "NONSSCTEST", full_name: avlj_name)
  end

  signing_vlj_name = "Smith Cash"
  let(:signing_vlj) do
    User.find_by_css_id("VLJTEST") ||
      create(:user, :vlj_user, css_id: "VLJTEST", full_name: signing_vlj_name)
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
      tied_judge: non_ssc_avlj,
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
      tied_judge: non_ssc_avlj,
      correspondent: correspondent,
      bfcorlid: "#{veteran.file_number}S",
      case_issues: create_list(:case_issue, 3, :compensation),
      bfd19: 7.days.ago
    )
  end

  context "#process and #tied_appeals" do
    # Base appeals not tied to non ssc avljs that should NOT be grabbed from the query
    let!(:not_ready_ama_original_appeal) { create(:appeal, :evidence_submission_docket, :with_post_intake_tasks) }
    let!(:ama_original_direct_review_appeal) { create(:appeal, :direct_review_docket, :ready_for_distribution) }
    let!(:ama_original_evidence_submission_appeal) do
      create(:appeal, :evidence_submission_docket, :ready_for_distribution)
    end

    let!(:not_ready_legacy_original_appeal) do
      create(:case_with_form_9, :type_original, :travel_board_hearing_requested)
    end
    let!(:legacy_original_appeal_no_hearing) { create(:case, :type_original, :ready_for_distribution) }

    # Appeals that should be grabbed with the Query
    let!(:legacy_unsigned_priority_tied_to_non_ssc_avlj) do
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_prio_case,
        closest_regional_office: "RO17"
      )
      create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
    end

    let!(:legacy_unsigned_non_priority_tied_to_non_ssc_avlj) do
      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_non_prio_case,
        closest_regional_office: "RO17"
      )
      create(:available_hearing_locations, "RO17", appeal: legacy_appeal)
    end

    let!(:legacy_signed_non_priority_tied_to_non_ssc_avlj) do
      create(:legacy_signed_appeal, :type_original, signing_avlj: signing_vlj, assigned_avlj: non_ssc_avlj)
    end

    let!(:legacy_signed_priority_tied_to_non_ssc_avlj) do
      create(:legacy_signed_appeal, :type_cavc_remand, signing_avlj: signing_vlj, assigned_avlj: non_ssc_avlj)
    end

    let!(:legacy_original_appeal_with_hearing) do
      create(:case, :type_original, :ready_for_distribution, case_hearings: [legacy_original_appeal_case_hearing])
    end
    let(:legacy_original_appeal_case_hearing) { build(:case_hearing, :disposition_held, user: hearing_judge) }

    let!(:ama_original_hearing_appeal) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute, tied_judge: hearing_judge)
    end

    it "selects all appeals tied to non ssc avlj and generates the CSV" do
      expect { described_class.process }.not_to raise_error
      expect(described_class.tied_appeals.size).to eq 6
    end
  end

  context "Test the CSV generation" do
    let!(:legacy_signed_appeal_with_attributes) do
      create(:legacy_signed_appeal, :type_original, signing_avlj: signing_vlj, assigned_avlj: non_ssc_avlj)
    end

    let!(:ama_appeal) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute, tied_judge: hearing_judge)
    end

    let(:legacy_query_result) { VACOLS::CaseDocket.appeals_tied_to_avljs_and_vljs }

    let(:docket) { HearingRequestDocket.new }
    let(:ama_query_result) { docket.tied_to_vljs(described_class.vlj_user_ids) }

    context "where it uses attributes " do
      it "to create a hash for AMA and Legacy rows" do
        subject_legacy = described_class.legacy_rows(legacy_query_result, :legacy).first
        subject_ama = described_class.ama_rows(ama_query_result, :hearing).first
        corres = legacy_signed_appeal_with_attributes.reload.correspondent
        corres_ama = ama_appeal.reload.veteran

        expect(subject_legacy[:docket_number]).to eq legacy_signed_appeal_with_attributes.folder.tinum
        expect(subject_legacy[:docket]).to eq "legacy"
        expect(subject_legacy[:priority]).to be ""
        expect(subject_legacy[:veteran_file_number]).to eq corres.ssn
        expect(subject_legacy[:veteran_name]).to eq "#{corres.snamef} #{corres.snamel}"
        expect(subject_legacy[:vlj]).to eq avlj_name
        expect(subject_legacy[:hearing_judge]).to eq avlj_name
        expect(subject_legacy[:most_recent_signing_judge]).to eq signing_vlj_name
        expect(subject_legacy[:bfcurloc]).to eq legacy_signed_appeal_with_attributes.bfcurloc

        expect(subject_ama[:docket_number]).to eq ama_appeal.docket_number
        expect(subject_ama[:docket]).to eq "hearing"
        expect(subject_ama[:priority]).to be false
        expect(subject_ama[:veteran_file_number]).to eq corres_ama.file_number
        expect(subject_ama[:veteran_name]).to eq corres_ama.name.to_s
        expect(subject_ama[:vlj]).to eq hearing_judge.full_name
        expect(subject_ama[:hearing_judge]).to eq hearing_judge.full_name
        expect(subject_ama[:most_recent_signing_judge]).to eq nil
        expect(subject_ama[:bfcurloc]).to eq nil
      end

      it "to verify that calculate_field_values is returning the correct items" do
        subject = described_class.calculate_field_values(legacy_query_result.first)

        corres = legacy_signed_appeal_with_attributes.reload.correspondent

        expect(subject[:veteran_file_number]).to eq corres.ssn
        expect(subject[:veteran_name]).to eq "#{corres.snamef} #{corres.snamel}"
        expect(subject[:vlj]).to eq avlj_name
        expect(subject[:hearing_judge]).to eq avlj_name
        expect(subject[:most_recent_signing_judge]).to eq signing_vlj_name
        expect(subject[:bfcurloc]).to eq legacy_signed_appeal_with_attributes.bfcurloc
      end
    end
  end
end
