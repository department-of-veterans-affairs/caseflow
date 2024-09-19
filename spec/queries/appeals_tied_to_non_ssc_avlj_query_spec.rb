# frozen_string_literal: true

describe AppealsTiedToNonSscAvljQuery do
  let(:hearing_judge) { create(:user, :judge, :with_vacols_judge_record) }
  let(:original_deciding_judge) { create(:user, :judge, :with_vacols_judge_record) }

  avlj_name = "John Doe"
  let(:non_ssc_avlj) do
    User.find_by_css_id("NONSSCTEST") ||
      create(:user, :non_ssc_avlj_user, css_id: "NONSSCTEST", full_name: avlj_name)
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
    let!(:ama_original_hearing_appeal) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute, tied_judge: hearing_judge)
    end

    let!(:not_ready_legacy_original_appeal) do
      create(:case_with_form_9, :type_original, :travel_board_hearing_requested)
    end
    let!(:legacy_original_appeal_no_hearing) { create(:case, :type_original, :ready_for_distribution) }
    let!(:legacy_original_appeal_with_hearing) do
      create(:case, :type_original, :ready_for_distribution, case_hearings: [legacy_original_appeal_case_hearing])
    end
    let(:legacy_original_appeal_case_hearing) { build(:case_hearing, :disposition_held, user: hearing_judge) }

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
      create(:legacy_signed_appeal, :type_original, signing_avlj: non_ssc_avlj, assigned_avlj: non_ssc_avlj)
    end

    let!(:legacy_signed_priority_tied_to_non_ssc_avlj) do
      create(:legacy_signed_appeal, :type_cavc_remand, signing_avlj: non_ssc_avlj, assigned_avlj: non_ssc_avlj)
    end

    it "selects all appeals tied to non ssc avlj and generates the CSV" do
      expect { described_class.process }.not_to raise_error
      expect(described_class.tied_appeals.size).to eq 4
    end
  end

  context "Test the CSV generation" do
    let!(:legacy_signed_appeal_with_attributes) do
      create(:legacy_signed_appeal, :type_original, signing_avlj: non_ssc_avlj, assigned_avlj: non_ssc_avlj)
    end

    let(:query_result) { VACOLS::CaseDocket.appeals_tied_to_non_ssc_avljs }

    subject { described_class.legacy_rows(query_result, :legacy).first }

    context "where it uses attributes " do
      it "to create a hash for the row" do
        corres = legacy_signed_appeal_with_attributes.reload.correspondent

        expect(subject[:docket_number]).to eq legacy_signed_appeal_with_attributes.folder.tinum
        expect(subject[:docket]).to eq "legacy"
        expect(subject[:priority]).to be ""
        expect(subject[:veteran_file_number]).to eq corres.ssn
        expect(subject[:veteran_name]).to eq "#{corres.snamef} #{corres.snamel}"
        expect(subject[:non_ssc_avlj]).to eq avlj_name
        expect(subject[:hearing_judge]).to eq avlj_name
        expect(subject[:most_recent_signing_judge]).to eq avlj_name
        expect(subject[:bfcurloc]).to eq legacy_signed_appeal_with_attributes.bfcurloc
      end

      context "to test getting the avlj name from appeal" do
        it "where appeals vlj is nil" do
          appeal = query_result.first
          appeal["vlj"] = nil
          expect(described_class.get_avlj_name(appeal)).to eq nil
        end
        it "where appeals vlj is not nil" do
          appeal = query_result.first
          expect(described_class.get_avlj_name(appeal)).to eq avlj_name
        end
      end

      context "to test getting the prev judges name from appeal" do
        it "where appeal has no prev deciding judge" do
          appeal = query_result.first
          appeal["prev_deciding_judge"] = nil
          expect(described_class.get_prev_judge_name(appeal)).to eq nil
        end
        it "where appeal has a previous deciding judge" do
          appeal = query_result.first
          expect(described_class.get_prev_judge_name(appeal)).to eq avlj_name
        end
      end
    end
  end
end
