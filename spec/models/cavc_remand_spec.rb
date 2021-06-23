# frozen_string_literal: true

describe CavcRemand do
  let(:created_by) { create(:user) }
  let(:updated_by) { create(:user) }
  let(:source_appeal) { create(:appeal) }
  let(:cavc_docket_number) { "123-1234567" }
  let(:represented_by_attorney) { true }
  let(:cavc_judge_full_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
  let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES.keys.first }
  let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES.keys.first }
  let(:decision_date) { 5.days.ago.to_date }
  let(:judgement_date) { 4.days.ago.to_date }
  let(:mandate_date) { 3.days.ago.to_date }
  let(:decision_issues) do
    create_list(
      :decision_issue,
      3,
      :rating,
      decision_review: source_appeal,
      disposition: "denied",
      description: "Decision issue description",
      decision_text: "decision issue"
    )
  end
  let(:decision_issue_ids) { decision_issues.map(&:id) }
  let(:federal_circuit) { nil }
  let(:instructions) { "Instructions!" }

  describe ".create!" do
    subject { CavcRemand.create!(params) }

    let(:params) do
      {
        created_by: created_by,
        updated_by: updated_by,
        source_appeal: source_appeal,
        cavc_docket_number: cavc_docket_number,
        represented_by_attorney: represented_by_attorney,
        cavc_judge_full_name: cavc_judge_full_name,
        cavc_decision_type: cavc_decision_type,
        remand_subtype: remand_subtype,
        decision_date: decision_date,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        decision_issue_ids: decision_issue_ids,
        federal_circuit: federal_circuit,
        instructions: instructions
      }
    end

    it "creates the record" do
      expect { subject }.not_to raise_error
      params.each_key { |key| expect(subject.send(key)).to eq params[key] }
    end

    it "creates the new court_remand cavc stream" do
      expect(Appeal.court_remand.where(stream_docket_number: source_appeal.docket_number).count).to eq(0)
      expect(source_appeal.aod_based_on_age).not_to be true

      cavc_remand = subject
      expect(cavc_remand.remand_appeal_id).not_to be(nil)
      cavc_appeal = Appeal.find(cavc_remand.remand_appeal_id)
      expect(cavc_appeal).not_to be(nil)
      expect(cavc_appeal.aod_based_on_age).not_to be true
    end

    context "when source appeal is AOD" do
      context "source appeal is AOD due to claimant's age" do
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_age) }
        it "creates new CAVC remand appeal with AOD due to age" do
          expect(source_appeal.aod_based_on_age).to be true

          cavc_remand = subject
          cavc_appeal = cavc_remand.remand_appeal
          expect(cavc_appeal.aod_based_on_age).to eq cavc_remand.source_appeal.aod_based_on_age
        end
      end
      context "source appeal has non-age-related AOD Motion" do
        let(:source_appeal) { create(:appeal, :active, :advanced_on_docket_due_to_motion) }
        it "copies AOD motions to new CAVC remand appeal" do
          person = source_appeal.claimant.person
          expect(AdvanceOnDocketMotion.granted_for_person?(person, source_appeal)).to be true
          aod_motions_count = AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, person).count
          expect(source_appeal.aod?).to be true

          cavc_remand = subject
          cavc_appeal = cavc_remand.remand_appeal
          expect(cavc_remand.source_appeal.claimant.person).to eq person
          expect(cavc_appeal.claimant.person).to eq person
          expect(AdvanceOnDocketMotion.for_appeal_and_person(source_appeal, person).count).to eq aod_motions_count
          expect(AdvanceOnDocketMotion.for_appeal_and_person(cavc_appeal, person).count).to eq aod_motions_count

          expect(AdvanceOnDocketMotion.granted_for_person?(cavc_appeal.claimant.person, cavc_appeal)).to be true
          expect(cavc_appeal.aod?).to be true
        end
      end
    end

    context "when missing required attributes" do
      context "for remands mandates" do
        let(:remand_subtype) { nil }

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES.keys.second }
      let(:created_by) { nil }
      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the judge is not in our list of judges" do
      let(:cavc_judge_full_name) { "Aaron Judge_HearingsAndCases Abshire" }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when JMR is missing issues" do
      let(:decision_issue_ids) { decision_issues.map(&:id).pop(2) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::JmrAppealDecisionIssueMismatch)
      end
    end

    shared_examples "works for all remand subtypes" do
      context "when remand subtype is MDR" do
        let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.mdr }
        let(:federal_circuit) { false }

        it "creates the record" do
          expect { subject }.not_to raise_error
        end
      end

      context "when remand subtype is JMR" do
        let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.jmr }

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when remand subtype is JMPR" do
        let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.jmpr }

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "when the mandate date is not set" do
      let(:mandate_date) {}

      include_examples "works for all remand subtypes"
    end

    context "when the judgement date is not set" do
      let(:judgement_date) {}

      include_examples "works for all remand subtypes"
    end
  end

  describe ".add_cavc_dates" do
    let(:remand_appeal_id) { cavc_remand.remand_appeal_id }
    let(:remand_appeal_uuid) { Appeal.find(cavc_remand.remand_appeal_id).uuid }
    let(:judgement_date) { 2.days.ago }
    let(:mandate_date) { 2.days.ago }
    let(:instructions) { "Do this!" }
    let(:params) do
      {
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        instructions: instructions
      }
    end

    subject { cavc_remand.add_cavc_dates(params) }

    context "on a JMR appeal" do
      let(:cavc_remand) { create(:cavc_remand) }
      it "throws an error" do
        expect { subject }.to raise_error(Caseflow::Error::CannotUpdateMandatedRemands)
      end
    end

    context "on an MDR appeal" do
      let!(:cavc_remand) { create(:cavc_remand, :mdr) }

      it "updates the cavc remand" do
        old_instructions = cavc_remand.instructions
        expect(cavc_remand.judgement_date).to be(nil)
        expect(cavc_remand.mandate_date).to be(nil)

        expect { subject }.not_to raise_error

        expect(cavc_remand.reload.instructions).to include(old_instructions)
        expect(cavc_remand.reload.instructions).to include(instructions)
        expect(cavc_remand.reload.judgement_date).to eq(judgement_date.to_date)
        expect(cavc_remand.reload.mandate_date).to eq(mandate_date.to_date)
      end

      it "completes the MDR hold" do
        cavc_task = CavcTask.find_by(appeal_id: remand_appeal_id)
        mdr_task = MdrTask.find_by(appeal_id: remand_appeal_id)
        hold_task = TimedHoldTask.find_by(appeal_id: remand_appeal_id)

        expect(cavc_task.open?).to be(true)
        expect(mdr_task.open?).to be(true)
        expect(hold_task.open?).to be(true)

        expect { subject }.not_to raise_error

        expect(cavc_task.reload.open?).to be(true)
        expect(mdr_task.reload.open?).to be(false)
        expect(hold_task.reload.open?).to be(false)
      end

      it "opens a CAVC Send Letter task" do
        expect { subject }.not_to raise_error
        expect(SendCavcRemandProcessedLetterTask.find_by(appeal_id: remand_appeal_id).open?).to be(true)
      end
    end

    shared_examples "shared straight reversal death dismissal flow" do |type|
      context "that had mandate" do
        let(:cavc_remand) { create(:cavc_remand, type) }
        it "throws an error" do
          expect { subject }.to raise_error(Caseflow::Error::CannotUpdateMandatedRemands)
        end
      end

      context "without mandate" do
        let!(:cavc_remand) { create(:cavc_remand, type, :no_mandate) }
        it "sends the appeal to distribution" do
          dist_task = DistributionTask.find_by(appeal_id: remand_appeal_id)
          cavc_task = CavcTask.find_by(appeal_id: remand_appeal_id)
          mandate_hold_task = MandateHoldTask.find_by(appeal_id: remand_appeal_id)
          hold_task = TimedHoldTask.find_by(appeal_id: remand_appeal_id)

          expect(dist_task.open?).to be(true)
          expect(cavc_task.open?).to be(true)
          expect(mandate_hold_task.open?).to be(true)
          expect(hold_task.open?).to be(true)

          expect { subject }.not_to raise_error

          expect(dist_task.reload.active?).to be(true)
          expect(cavc_task.reload.open?).to be(false)
          expect(mandate_hold_task.reload.open?).to be(false)
          expect(hold_task.reload.open?).to be(false)
        end
      end
    end

    context "on a Straight Reversal appeal" do
      include_examples "shared straight reversal death dismissal flow", :straight_reversal
    end

    context "on a Death Dismissal appeal" do
      include_examples "shared straight reversal death dismissal flow", :death_dismissal
    end
  end

  describe ".update" do
    let!(:cavc_remand) do
      create(:cavc_remand, :jmpr,
             decision_issues_selected_count: 1)
    end

    let(:params) do
      {
        decision_issue_ids: updated_decision_issue_ids,
        source_appeal_id: source_appeal.id,
        cavc_decision_type: Constants::CAVC_DECISION_TYPES.keys.first,
        cavc_docket_number: "123-1234567",
        cavc_judge_full_name: cavc_judge_full_name,
        decision_date: decision_date.to_s,
        judgement_date: judgement_date.to_s,
        mandate_date: mandate_date.to_s,
        instructions: "Instructions here!",
        represented_by_attorney: true,
        remand_subtype: remand_subtype,
        federal_circuit: false
      }
    end

    subject { cavc_remand.update(params) }

    context "removes decision issue ids" do
      let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.jmr }
      let(:remaining_decision_issue_id) { cavc_remand.decision_issue_ids.first }
      let(:updated_decision_issue_ids) { [remaining_decision_issue_id] }

      it "successfully removes decision issue ids that should be removed" do
        expect(cavc_remand.remand_appeal.request_issues.length).to eq(1)
        expect { subject }.not_to raise_error

        expect(cavc_remand.decision_issue_ids[0]).to eq(remaining_decision_issue_id)
        expect(cavc_remand.decision_issue_ids.length).to eq(1)
        expect(cavc_remand.remand_appeal.reload.request_issues.length).to eq(1)
      end
    end

    context "adds decision issue ids" do
      let(:remand_subtype) { Constants.CAVC_REMAND_SUBTYPES.jmr }
      let(:updated_decision_issue_ids) { cavc_remand.source_appeal.decision_issue_ids }

      it "successfully adds decision issue ids that should be added" do
        expect(cavc_remand.remand_appeal.request_issues.length).to eq(1)
        expect { subject }.not_to raise_error

        expect(cavc_remand.decision_issue_ids.length).to eq(3)
        expect(cavc_remand.remand_appeal.reload.request_issues.length).to eq(3)
      end
    end
  end
end
