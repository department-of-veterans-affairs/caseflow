# frozen_string_literal: true

RSpec.describe HomeController, :postgres, type: :controller do
  describe "GET /" do
    context "when visitor is not logged in" do
      let!(:current_user) { nil }
      it "should redirect to /help" do
        get :index
        expect(response.status).to eq 302
        expect(URI.parse(response.location).path).to eq("/help")
      end
    end

    context "when visitor is logged in" do
      let!(:current_user) { User.authenticate! }

      it "should set timezone in session if is not set and restore it" do
        initial_time_zone = Time.zone
        expect(@request.session[:timezone]).to eq nil

        RSpec::Mocks.with_temporary_scope do
          get :index
          allow(Time).to receive(:zone=).and_call_original
          allow(Time).to receive(:zone=).with(current_user.timezone).once
          expect(@request.session[:timezone]).to eq current_user.timezone
        end

        expect(Time.zone).to eq initial_time_zone
      end

      it "should use session's value if is already set and restore it" do
        initial_time_zone = Time.zone
        @request.session[:timezone] = "America/Chicago"

        RSpec::Mocks.with_temporary_scope do
          allow(Time).to receive(:zone=).and_call_original
          allow(Time).to receive(:zone=).with("America/Chicago").once
          get :index
          expect(@request.session[:timezone]).to eq "America/Chicago"
        end
        
        expect(Time.zone).to eq initial_time_zone
      end
    end

    context "when visitor is logged in, does not have a personal queue but does have case search access" do
      let!(:current_user) { User.authenticate! }

      it "should land at /" do
        get :index
        expect(response.status).to eq 200
      end
    end
  end
end
