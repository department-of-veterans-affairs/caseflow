# frozen_string_literal: true

describe Reader::AppealController, :postgres, type: :controller do
  let(:attorney_user) { create(:user, roles: ["Reader"]) }
  let(:appeal) { create(:appeal) }
  let(:request_params) { { id: appeal.uuid } }

  before { User.authenticate!(user: attorney_user) }
  after { User.unauthenticate! }

  subject { get(:show, params: request_params, format: :json) }

  describe "#show" do
    context "when the request has a json format" do
      it "returns a successful response" do
        subject
        assert_response(:success)
      end
    end
  end
end
