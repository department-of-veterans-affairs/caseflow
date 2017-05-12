# spec/controllers/articles_controller_spec.rb
require "rails_helper"

RSpec.describe CertificationCancellationsController, type: :controller do
  let!(:current_user) { User.authenticate! }

  describe "Responds to" do
    context "responds to HTML format" do
      it "when it passes validation" do
        post :create, "certification_cancellation" =>
          { "cancellation_reason" => "Test",
            "other_reason" => "", "email" => "test@gmail.com", "certification_id" => "1" }
        expect(response).to have_http_status(:redirect)
      end

      it "when it fails validation" do
        post :create, "certification_cancellation" =>
          { "cancellation_reason" => "",
            "other_reason" => "", "email" => "test@gmail.com", "certification_id" => "2" }
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context "responds to JSON format" do
      before(:each) do
        request.headers["HTTP_ACCEPT"] = "application/json"
        request.headers["CONTENT_TYPE"] = "application/json"
      end

      it "when it passes validation" do
        post :create, "certification_cancellation" =>
          { "cancellation_reason" => "Test",
            "other_reason" => "", "email" => "test@gmail.com", "certification_id" => "3" }
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to match("is_cancelled" => true)
      end

      it "when it fails validation" do
        post :create, { "certification_cancellation" =>
          { "cancellation_reason" => "",
            "other_reason" => "", "email" => "test@gmail.com",
            "certification_id" => "4" } }, accept: :json, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to match("is_cancelled" => false)
      end
    end
  end
end
