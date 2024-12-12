# frozen_string_literal: true

describe AppealsReadyForDistribution do
  let(:hearing_judge) { create(:user, :judge, :with_vacols_judge_record) }
  let(:original_deciding_judge) { create(:user, :judge, :with_vacols_judge_record) }

  context "#process and #ready_appeals" do
    let!(:not_ready_ama_original_appeal) { create(:appeal, :evidence_submission_docket, :with_post_intake_tasks) }
    let!(:ama_original_direct_review_appeal) { create(:appeal, :direct_review_docket, :ready_for_distribution) }
    let!(:ama_original_evidence_submission_appeal) do
      create(:appeal, :evidence_submission_docket, :ready_for_distribution)
    end
    let!(:ama_original_hearing_appeal) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute, tied_judge: hearing_judge)
    end
    let!(:ama_cavc_direct_review_appeal) { create_realistic_cavc_case(Constants.AMA_DOCKETS.direct_review) }
    let!(:ama_cavc_evidence_submission_appeal) do
      create_realistic_cavc_case(Constants.AMA_DOCKETS.evidence_submission)
    end
    let!(:ama_cavc_hearing_appeal) { create_realistic_cavc_case(Constants.AMA_DOCKETS.hearing) }

    # below legacy cases are selected by VACOLS::CaseDocket
    let!(:not_ready_legacy_original_appeal) do
      create(:case_with_form_9, :type_original, :travel_board_hearing_requested)
    end
    let!(:legacy_original_appeal_no_hearing) { create(:case, :type_original, :ready_for_distribution) }
    let!(:legacy_original_appeal_with_hearing) do
      create(:case, :type_original, :ready_for_distribution, case_hearings: [legacy_original_appeal_case_hearing])
    end
    let(:legacy_original_appeal_case_hearing) { build(:case_hearing, :disposition_held, user: hearing_judge) }
    let!(:legacy_cavc_appeal_no_hearing) do
      original = create(:legacy_cavc_appeal, judge: original_deciding_judge.vacols_staff)
      VACOLS::Case.find_by(bfcorlid: original.bfcorlid, bfmpro: "ACT")
    end
    let!(:legacy_cavc_appeal_with_hearing) do
      original = create(:legacy_cavc_appeal, judge: original_deciding_judge.vacols_staff)
      create(:case_hearing, :disposition_held, folder_nr: original.bfkey, user: hearing_judge)
      VACOLS::Case.find_by(bfcorlid: original.bfcorlid, bfmpro: "ACT")
    end

    # below legacy cases are selected by VACOLS::AojCaseDocket
    let!(:legacy_aoj_appeal_no_hearing) do
      create(:legacy_aoj_appeal, judge: original_deciding_judge.vacols_staff, tied_to: false)
    end
    let!(:legacy_aoj_appeal_with_hearing) do
      create(:legacy_aoj_appeal, judge: original_deciding_judge.vacols_staff)
    end

    it "selects all ready to distribute appeals for all dockets and generates the CSV" do
      expect { described_class.process }.not_to raise_error
      expect(described_class.ready_appeals.size).to eq 12
    end
  end

  context "legacy_rows" do
    let!(:legacy_appeal_with_attributes) do
      create(:case, :type_original, :aod, :ready_for_distribution, :with_appeal_affinity, case_hearings: [case_hearing])
    end
    let(:case_hearing) { build(:case_hearing, :disposition_held, user: hearing_judge) }
    let(:query_result) { VACOLS::CaseDocket.ready_to_distribute_appeals }

    subject { described_class.legacy_rows(query_result, :legacy).first }

    it "correctly uses attributes to create a hash for the row" do
      corres = legacy_appeal_with_attributes.reload.correspondent

      expect(subject[:docket_number]).to eq legacy_appeal_with_attributes.folder.tinum
      expect(subject[:docket]).to eq "legacy"
      expect(subject[:aod]).to be true
      expect(subject[:cavc]).to be false
      expect(subject[:receipt_date]).to eq legacy_appeal_with_attributes.bfd19
      expect(subject[:ready_for_distribution_at]).to eq legacy_appeal_with_attributes.bfdloout
      expect(subject[:hearing_judge]).to eq hearing_judge.full_name
      expect(subject[:original_judge]).to be nil
      expect(subject[:veteran_file_number]).to eq legacy_appeal_with_attributes.bfcorlid
      expect(subject[:veteran_name]).to eq "#{corres.snamef} #{corres.snamel}"
      expect(subject[:affinity_start_date]).to eq legacy_appeal_with_attributes.appeal_affinity.affinity_start_date
    end
  end

  context "ama_rows" do
    let!(:ama_appeal_with_attributes) do
      create(
        :appeal,
        :hearing_docket,
        :advanced_on_docket_due_to_motion,
        :held_hearing_and_ready_to_distribute,
        :with_appeal_affinity,
        tied_judge: hearing_judge
      )
    end
    let(:query_result) { HearingRequestDocket.new.ready_to_distribute_appeals }

    subject { described_class.ama_rows(query_result, HearingRequestDocket.new, :hearing).first }

    it "correctly uses the attributes to create a hash for the row" do
      # Reload to update the appeal_affinity record correctly in memory because of eager loading
      ama_appeal_with_attributes.reload

      expect(subject[:docket_number]).to eq ama_appeal_with_attributes.docket_number
      expect(subject[:docket]).to eq "hearing"
      expect(subject[:aod]).to be true
      expect(subject[:cavc]).to be false
      expect(subject[:receipt_date]).to eq ama_appeal_with_attributes.receipt_date
      expect(subject[:ready_for_distribution_at])
        .to eq ama_appeal_with_attributes.tasks.where(type: DistributionTask.name).first.assigned_at
      expect(subject[:hearing_judge]).to eq ama_appeal_with_attributes.hearings.first.judge.full_name
      expect(subject[:original_judge]).to be nil
      expect(subject[:veteran_file_number]).to eq ama_appeal_with_attributes.veteran_file_number
      expect(subject[:veteran_name]).to eq ama_appeal_with_attributes.veteran.name.to_s
      expect(subject[:affinity_start_date]).to eq ama_appeal_with_attributes.appeal_affinity.affinity_start_date
    end
  end

  context "ama_cavc_original_deciding_judge" do
    let!(:appeal) { create_realistic_cavc_case(Constants.AMA_DOCKETS.direct_review) }

    it "returns the original judge's CSS_ID" do
      expect(described_class.ama_cavc_original_deciding_judge(appeal)).to eq original_deciding_judge.css_id
    end
  end

  context "legacy_original_deciding_judge" do
    let!(:legacy_appeal) do
      { "bfkey" => "test_key_pls_ignore", "prev_deciding_judge" => original_deciding_judge.vacols_staff.sattyid }
    end

    it "returns the original judge's SDOMAINID if present" do
      expect(described_class.legacy_original_deciding_judge(legacy_appeal)).to eq original_deciding_judge.css_id
    end

    context "when the original judge has no SDOMAINID" do
      before { original_deciding_judge.vacols_staff.update!(sdomainid: nil) }

      it "returns the prev_deciding_judge value from the query" do
        expect(described_class.legacy_original_deciding_judge(legacy_appeal))
          .to eq legacy_appeal["prev_deciding_judge"]
      end
    end
  end

  def create_realistic_cavc_case(docket)
    docket_trait = "#{docket}_docket".to_s
    source = Timecop.travel(1.year.ago) do
      create(:appeal, docket_trait, :dispatched, associated_judge: original_deciding_judge)
    end
    remand = create(:cavc_remand, source_appeal: source)
    remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
    create(:appeal_affinity, appeal: remand.remand_appeal)
    remand.remand_appeal
  end
end
