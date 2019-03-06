# frozen_string_literal: true

shared_examples "IDT access verification" do |http_method, action, params|
  describe "access verification before_action" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }

    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    context "when request header does not contain token" do
      it "response should error" do
        if params
          public_send(http_method, action, params: params)
        else
          public_send(http_method, action)
        end
        expect(response.status).to eq 400
      end
    end

    context "when request header contains invalid token" do
      before { request.headers["TOKEN"] = "3289fn893rnqi8hf3nf" }

      it "responds with an error" do
        if params
          public_send(http_method, action, params: params)
        else
          public_send(http_method, action)
        end
        expect(response.status).to eq 403
      end
    end

    context "when request header contains inactive token" do
      before do
        _key, t = Idt::Token.generate_one_time_key_and_proposed_token
        request.headers["TOKEN"] = t
      end

      it "responds with an error" do
        if params
          public_send(http_method, action, params: params)
        else
          public_send(http_method, action)
        end

        expect(response.status).to eq 403
      end
    end

    context "when request header contains valid token but the user is not authorized" do
      before do
        request.headers["TOKEN"] = token
      end

      it "responds with an error" do
        if params
          public_send(http_method, action, params: params)
        else
          public_send(http_method, action)
        end

        err_msg = JSON.parse(response.body)["message"]

        expect(err_msg).to eq "User must be attorney, judge, dispatch, or intake"
        expect(response.status).to eq 403
      end
    end
  end
end
