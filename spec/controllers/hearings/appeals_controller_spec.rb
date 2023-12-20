# frozen_string_literal: true

RSpec.describe Hearings::AppealsController, :all_dbs, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_form_9)
  end

  describe "PATCH update" do
    it "add a new issue" do
      params = { worksheet_issues_attributes: [
        {
          remand: true,
          omo: false,
          description: "Wheel",
          notes: "Donkey Cow",
          from_vacols: false,
          vacols_sequence_id: 1
        }
      ] }
      patch :update, params: { appeal_id: appeal.id, appeal: params }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["appeal"]
      expect(response_body["worksheet_issues"].size).to eq 1
      expect(response_body["worksheet_issues"][0]["remand"]).to eq true
      expect(response_body["worksheet_issues"][0]["omo"]).to eq false
      expect(response_body["worksheet_issues"][0]["description"]).to eq "Wheel"
      expect(response_body["worksheet_issues"][0]["notes"]).to eq "Donkey Cow"
      expect(response_body["worksheet_issues"][0]["from_vacols"]).to eq false
      expect(response_body["worksheet_issues"][0]["vacols_sequence_id"]).to eq "1"
    end

    it "delete an issue" do
      issue = Generators::WorksheetIssue.create(appeal: appeal)
      expect(WorksheetIssue.all.size).to eq 1
      params = { worksheet_issues_attributes: [{ _destroy: true, id: issue.id }] }
      patch :update, params: { appeal_id: appeal.id, appeal: params }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["appeal"]
      expect(WorksheetIssue.all.size).to eq 0
      expect(response_body["worksheet_issues"].size).to eq 0
    end

    it "should return not found" do
      patch :update, params: { appeal_id: "534553", appeal: {} }
      expect(response.status).to eq 404
    end
  end
end
