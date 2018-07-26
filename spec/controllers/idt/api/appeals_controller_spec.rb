RSpec.describe Idt::Api::V1::AppealsController, type: :controller do
  describe "GET /idt/api/v1/appeals" do
    let(:user) { create(:user, { css_id: "TEST_ID" } ) }

    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    context "when request header does not contain token" do
      it "response should error" do
        get :index
        expect(response.status).to eq 400
      end
    end

    context "when request header contains invalid token" do
      before { request.headers["TOKEN"] = "3289fn893rnqi8hf3nf" }

      it "responds with an error" do
        get :index
        expect(response.status).to eq 403
      end
    end

    context "when request header contains inactive token" do
      before do
        _key, t = Idt::Token.generate_one_time_key_and_proposed_token
        request.headers["TOKEN"] = t
      end

      it "responds with an error" do
        get :index
        expect(response.status).to eq 403
      end
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

      context "and user is not an attorney" do
        let(:role) { :colocated_role }
        let(:user) { create(:user, { css_id: "ANOTHER_TEST_ID" }) }

        before do
          request.headers["TOKEN"] = token
        end

        it "returns an error" do
          get :index
          expect(response.status).to eq 403
        end
      end
    end
  end
end
