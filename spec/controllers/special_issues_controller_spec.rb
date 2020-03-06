# frozen_string_literal: true

RSpec.describe SpecialIssuesController, :all_dbs, type: :controller do
  describe "GET tasks/xxx" do
    let(:user) { create(:user) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)) }

    before { User.authenticate!(user: user) }

    context "when user does not have access to the appeal" do
      before do
        allow(QueueRepository).to receive(:tasks_for_user).with(user.css_id).and_return([])
      end

      it "should return unauthorized" do
        expect(Raven).to_not receive(:capture_exception)

        get :index, params: { appeal_id: appeal.vacols_id }

        expect(response.status).to eq 302
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "when does have access to the appeal" do
      it "should return ok" do
        get :index, params: { appeal_id: appeal.vacols_id }

        expect(response.status).to eq 200
      end
    end
  end
end
