# frozen_string_literal: true

RSpec.describe CertificationCancellationsController, :postgres, type: :controller do
  let!(:current_user) { User.authenticate! }

  describe "Responds to" do
    context "responds to JSON format" do
      before(:each) do
        request.headers["HTTP_ACCEPT"] = "application/json"
        request.headers["CONTENT_TYPE"] = "application/json"
      end

      it "when it passes validation" do
        post :create, params: { "certification_cancellation" =>
            { "cancellation_reason" => "Test",
              "other_reason" => "", "email" => "test@gmail.com", "certification_id" => "3" } }
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to match("is_cancelled" => true)
      end

      it "when it fails validation" do
        post :create, params: { "certification_cancellation" =>
                            { "cancellation_reason" => "",
                              "other_reason" => "", "email" => "test@gmail.com",
                              "certification_id" => "4" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to match("is_cancelled" => false)
      end
    end
  end
end
