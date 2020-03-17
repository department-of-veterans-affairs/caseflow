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
      let(:chicago_ro_central) { "RO28" }
      let!(:current_user) do
        User.authenticate!(user: create(:user, regional_office: chicago_ro_central, station_id: 328))
      end

      it "should set timezone in session if is not set and restore it" do
        initial_time_zone = Time.zone
        expect(@request.session[:timezone]).to eq nil

        allow(Time).to receive(:zone=).and_call_original
        expect(Time).to receive(:zone=).with(current_user.timezone).once.and_call_original
        get :index
        expect(@request.session[:timezone]).to eq current_user.timezone

        expect(Time.zone).to eq initial_time_zone
      end

      it "should use session's value if is already set and restore it" do
        initial_time_zone = Time.zone
        @request.session[:timezone] = "America/Chicago"

        allow(Time).to receive(:zone=).and_call_original
        expect(Time).to receive(:zone=).with("America/Chicago").once.and_call_original
        get :index
        expect(@request.session[:timezone]).to eq "America/Chicago"

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
