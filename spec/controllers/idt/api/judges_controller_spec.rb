# frozen_string_literal: true

RSpec.describe Idt::Api::V1::JudgesController, :all_dbs, type: :controller do
  describe "GET /idt/api/v1/judges" do
    let(:user) { create(:user, css_id: "TEST_ID") }

    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    context "when request header contains valid token" do
      context "and user is an attorney" do
        let(:role) { :attorney_role }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        it "succeeds" do
          get :index
          expect(response.status).to eq 200
        end
      end
    end
  end
end
