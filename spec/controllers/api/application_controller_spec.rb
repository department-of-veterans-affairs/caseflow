# frozen_string_literal: true

describe Api::ApplicationController do
  context "VBMS raises a transient error" do
    controller do
      def index
        fail VBMS::HTTPError.new("500", "Could not access remote service at\255")
      end
    end

    it "rescues and does not send to Sentry" do
      allow(controller).to receive(:verify_authentication_token).and_return(true)
      expect(Raven).to_not receive(:capture_exception)
      expect(Rails.logger).to receive(:error)

      get :index

      response_json = {
        "errors" => [
          "status" => "503",
          "title" => "Service unavailable",
          "detail" => "Upstream service timed out or unavailable to process the request"
        ]
      }

      expect(JSON.parse(response.body)).to eq response_json
      expect(response.status).to eq 503
    end
  end

  context "VBMS raises a non-transient error" do
    controller do
      def index
        fail VBMS::HTTPError.new("500", "not transient\255")
      end
    end

    it "rescues and sends to Sentry" do
      allow(controller).to receive(:verify_authentication_token).and_return(true)
      expect(Raven).to receive(:capture_exception)
      expect(Rails.logger).to_not receive(:error)

      get :index

      response_json = {
        "errors" => [
          "status" => "500",
          "title" => "Bad request",
          "detail" => "not transient"
        ]
      }

      expect(JSON.parse(response.body)).to eq response_json
      expect(response.status).to eq 500
    end
  end

  context "BGS raises a transient error" do
    controller do
      def index
        fail BGS::ShareError, "execution expired\255"
      end
    end

    it "rescues and does not send to Sentry" do
      allow(controller).to receive(:verify_authentication_token).and_return(true)
      expect(Raven).to_not receive(:capture_exception)
      expect(Rails.logger).to receive(:error)

      get :index

      response_json = {
        "errors" => [
          "status" => "503",
          "title" => "Service unavailable",
          "detail" => "Upstream service timed out or unavailable to process the request"
        ]
      }

      expect(JSON.parse(response.body)).to eq response_json
    end
  end

  context "BGS raises a non-transient error" do
    controller do
      def index
        fail BGS::ShareError.new("not transient\255", 503)
      end
    end

    it "rescues and sends to Sentry" do
      allow(controller).to receive(:verify_authentication_token).and_return(true)
      expect(Raven).to receive(:capture_exception)
      expect(Rails.logger).to_not receive(:error)

      get :index

      response_json = {
        "errors" => [
          "status" => 503,
          "title" => "Bad request",
          "detail" => "not transient"
        ]
      }

      expect(JSON.parse(response.body)).to eq response_json
      expect(response.status).to eq 503
    end
  end
end
