# frozen_string_literal: true

describe CavcRemand do
  fdescribe ".create!" do
    subject { CavcRemand.create!(params) }

    let(:created_by) { create(:user) }
    let(:updated_by) { create(:user) }
    let(:appeal) { create(:appeal) }
    let(:attorney_represented) { true }
    let(:cavc_judge_full_name) { Constants.CAVC_JUDGE_FULL_NAMES.first }
    let(:type) { Constants.CAVC_TYPES.first  }
    let(:remand_type) { Constants.CAVC_REMAND_TYPES.first  }
    let(:decision_date) { 5.days.ago }
    let(:judgement_date) { 4.days.ago }
    let(:mandate_date) { 3.days.ago }
    let(:decision_issue_ids) do
      create_list(
        :decision_issue,
        3,
        :rating,
        decision_review: appeal,
        disposition: "denied",
        description: "Decision issue description",
        decision_text: "decision issue"
      ).map(&:id)
    end
    let(:instructions) { "Intructions!" }

    let(:params) do
      {
        created_by: created_by,
        updated_by: updated_by,
        appeal: appeal,
        attorney_represented: attorney_represented,
        cavc_judge_full_name: cavc_judge_full_name,
        type: type,
        remand_type: remand_type,
        decision_date: decision_date,
        judgement_date: judgement_date,
        mandate_date: mandate_date,
        decision_issue_ids: decision_issue_ids,
        instructions: instructions
      }
    end

    it "creates the record" do
      expect { subject }.not_to raise_error
      params.keys.each { |key| expect(subject.send(key)).to eq params[key] }
    end

    context "when missing required attributes" do
      let(:created_by) { nil }

      it "does not save the record" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "When the judge is not in our list of judges" do
      let(:cavc_judge_full_name) { "Aaron Judge_HearingsAndCases Abshire" }

      it "does not save the record" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
