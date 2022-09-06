# frozen_string_literal: true

describe DocketCoordinator do

  shared_examples "correct priority count" do
    let(:judge) { create(:user, :with_vacols_judge_record) }

    let(:tied_legacy_case_count) { 5 }
    let(:genpop_legacy_case_count) { 4 }
    let(:tied_ama_hearing_case_count) { 3 }
    let(:genpop_ama_hearing_case_count) { 2 }
    let(:genpop_direct_case_count) { 2 }
    let(:genpop_evidence_case_count) { 2 }

    let(:genpop_priority_cases_count) do
      genpop_legacy_case_count + genpop_ama_hearing_case_count + genpop_direct_case_count + genpop_evidence_case_count + tied_ama_hearing_case_count
    end
    let(:all_priority_cases_count) do
      genpop_priority_cases_count + tied_legacy_case_count
    end

    before do
      tied_legacy_case_count.times { create(:case, :type_cavc_remand, :ready_for_distribution, :tied_to_judge, tied_judge: judge) }
      genpop_legacy_case_count.times { create(:case, :type_cavc_remand, :ready_for_distribution) }
      tied_ama_hearing_case_count.times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          :tied_to_judge,
          tied_judge: judge,
          adding_user: judge
        )
      end
      genpop_ama_hearing_case_count.times do
        create(
          :appeal,
          :hearing_docket,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          :held_hearing,
          adding_user: judge
        )
      end
      genpop_direct_case_count.times do
        create(:appeal, :direct_review_docket, :ready_for_distribution, :advanced_on_docket_due_to_age)
      end
      genpop_evidence_case_count.times do
        create(:appeal, :evidence_submission_docket, :ready_for_distribution, :advanced_on_docket_due_to_age)
      end
    end

    it "returns the count of all priority cases that are ready to be distributed" do
      expect(subject).to eq expected_priority_count
    end
  end

  describe "#priority_count" do
    subject { DocketCoordinator.new.priority_count }

    let(:expected_priority_count) { all_priority_cases_count }

    it_behaves_like "correct priority count"
  end

  describe "#genpop_priority_count" do
    subject { DocketCoordinator.new.genpop_priority_count }

    let(:expected_priority_count) { genpop_priority_cases_count }

    it_behaves_like "correct priority count"
  end
end
