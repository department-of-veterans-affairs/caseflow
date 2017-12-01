RSpec.describe Hearings::WorksheetsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let(:appeal) { Generators::Appeal.create(vacols_record: :ready_to_certify) }
  let(:hearing) { Generators::Hearing.create(appeal: appeal) }

  describe "PATCH update" do
    it "add a new issue" do
      params = { worksheet_issues_attributes: [
        {
          remand: true,
          vha: false,
          program: "Wheel",
          name: "Spoon",
          levels: "Cabbage Pickle",
          description: "Donkey Cow",
          from_vacols: false,
          vacols_sequence_id: 1
        }]
                }
      patch :update, hearing_id: hearing.id, worksheet: params
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["worksheet"]
      expect(response_body["worksheet_issues"].size).to eq 1
      expect(response_body["worksheet_issues"][0]["remand"]).to eq true
      expect(response_body["worksheet_issues"][0]["vha"]).to eq false
      expect(response_body["worksheet_issues"][0]["program"]).to eq "Wheel"
      expect(response_body["worksheet_issues"][0]["name"]).to eq "Spoon"
      expect(response_body["worksheet_issues"][0]["levels"]).to eq "Cabbage Pickle"
      expect(response_body["worksheet_issues"][0]["description"]).to eq "Donkey Cow"
      expect(response_body["worksheet_issues"][0]["from_vacols"]).to eq false
      expect(response_body["worksheet_issues"][0]["vacols_sequence_id"]).to eq "1"
    end

    it "delete an issue" do
      issue = Generators::WorksheetIssue.create(appeal: appeal)
      expect(WorksheetIssue.all.size).to eq 1
      params = { worksheet_issues_attributes: [{ _destroy: "1", id: issue.id }] }
      patch :update, hearing_id: hearing.id, worksheet: params
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)["worksheet"]
      expect(WorksheetIssue.all.size).to eq 0
      expect(response_body["worksheet_issues"].size).to eq 0
    end

    it "should return not found" do
      patch :update, hearing_id: "534553", worksheet: {}
      expect(response.status).to eq 404
    end
  end
end
