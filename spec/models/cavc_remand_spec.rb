# frozen_string_literal: true

describe CavcRemand do
  describe ".create!" do
    subject { CavcRemand.create!(params) }

    let(:created_by) { create(:user) }
    let(:updated_by) { create(:user) }
    let(:appeal) { create(:appeal) }
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
        decision_review: appeal,
        disposition: "denied",
        description: "Decision issue description",
        decision_text: "decision issue"
      )
    end
    let(:decision_issue_ids) { decision_issues.map(&:id) }
    let(:instructions) { "Intructions!" }

    let(:params) do
      {
        created_by: created_by,
        updated_by: updated_by,
        appeal: appeal,
        cavc_docket_number: cavc_docket_number,
        represented_by_attorney: represented_by_attorney,
        cavc_judge_full_name: cavc_judge_full_name,
        cavc_decision_type: cavc_decision_type,
        remand_subtype: remand_subtype,
        decision_date: decision_date,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        decision_issue_ids: decision_issue_ids,
        instructions: instructions
      }
    end

    it "creates the record" do
      expect { subject }.not_to raise_error
      params.each_key { |key| expect(subject.send(key)).to eq params[key] }
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
end
