# frozen_string_literal: true

RSpec.describe Idt::AuthenticationsController, :postgres, type: :controller do
  describe "GET /idt/auth" do
    let(:one_time_key) do
      Idt::Token.generate_one_time_key_and_proposed_token[0]
    end
    let(:css_id) { "TEST_ID" }

    let(:activated_one_time_key) do
      key = Idt::Token.generate_one_time_key_and_proposed_token[0]
      Idt::Token.activate_proposed_token(key, css_id)
      key
    end

    context "when not authenticated" do
      it "redirects" do
        get :index, params: { one_time_key: one_time_key }
        expect(response.status).to eq 302
      end
    end

    context "when authenticated" do
      before { User.authenticate!(user: build_stubbed(:user)) }

      context "when no key is passed" do
        it "responds witn an error" do
          get :index
          expect(response.status).to eq 400
        end
      end

      context "when request header contains a key that was already activated" do
        it "responds with an error" do
          get :index, params: { one_time_key: activated_one_time_key }
          expect(response.status).to eq 400
        end
      end

      context "when request header contains valid key" do
        it "succeeds" do
          get :index, params: { one_time_key: one_time_key }
          expect(response.status).to eq 200
        end
      end
    end
  end
end
