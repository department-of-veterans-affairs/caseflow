# frozen_string_literal: true

describe "SSL Redirects" do
  # CaseflowCertification::Application is already loaded at this stage.
  # We can't modify the middleware stack as it's frozen, so subclass it season to taste:
  def app_with_production_ssl_config
    @app_with_production_ssl_config ||= Class.new(Rails.application.class) do
      config.force_ssl = true
      config.ssl_options = {
          hsts: {
            subdomains:  true
          },
          redirect: { exclude: SslRedirectExclusionPolicy }
      }
    end
  end

  # `app´ is what RSpec tests against in request specs. Think `controller´
  # for controller specs. Override it with our modified app.
  def app
    @app ||= app_with_production_ssl_config
  end

  before { allow(SslRedirectExclusionPolicy).to receive(:call).and_call_original }

  context "when request is not SSL" do
    context "when path matches '/api/docs/v3/'" do
      it "is exempt from SSL redirect" do
        get "/api/docs/v3/decision_reviews"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).not_to have_http_status(:redirect)
      end
    end

    context "when path is '/api/metadata'" do
      it "is exempt from SSL redirect" do
        get "/api/metadata"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).not_to have_http_status(:redirect)
      end
    end

    context "when path is '/health-check'" do
      it "is exempt from SSL redirect" do
        get "/health-check"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).not_to have_http_status(:redirect)
      end
    end

    context "when path matches '/idt/api/v1/'" do
      it "is exempt from SSL redirect" do
        get "/idt/api/v1/appeals"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).not_to have_http_status(:redirect)
      end
    end

    context "when path matches '/idt/api/v2/'" do
      it "is exempt from SSL redirect" do
        get "/idt/api/v2/appeals"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).not_to have_http_status(:redirect)
      end
    end

    context "when path is not exempt from SSL redirects" do
      it "is redirected" do
        get "/users"
        expect(SslRedirectExclusionPolicy).to have_received(:call)
        expect(response).to redirect_to("https://#{request.host}/users")
      end
    end
  end
end
