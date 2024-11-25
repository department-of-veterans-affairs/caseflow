describe Hearings::NationalHearingQueueController, type: :controller do
  before { User.authenticate!(roles: ["Build Hearsched", "Edit Hearsched"]) }

  context "GET cutoff_date" do
    subject { get :cutoff_date }

    context "Whenever no user-provided cutoff dates exists in the database" do
      it "Returns the default value of 12/31/2019" do
        parsed_body = JSON.parse(subject.body)

        expect(parsed_body["cutoff_date"]).to eq "2019-12-31"
        expect(parsed_body["user_can_edit"]).to eq false
        expect(subject.response_code).to eq 200
      end
    end

    context "Whenever a user-provided cutoff date(s) exist in the database" do
      let(:new_cutoff_date) { "2024-11-25" }
      let!(:cutoff_date_record) { create(:schedulable_cutoff_date, cutoff_date: new_cutoff_date) }

      it "Returns the date corresponding with whichever record is the most recent" do
        parsed_body = JSON.parse(subject.body)

        expect(parsed_body["cutoff_date"]).to eq new_cutoff_date
        expect(parsed_body["user_can_edit"]).to eq false
        expect(subject.response_code).to eq 200
      end
    end
  end
end
