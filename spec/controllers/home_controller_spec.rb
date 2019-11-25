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

      it "should set timezone in session if is not set" do
        expect(@request.session[:timezone]).to eq nil
        get :index
        expect(Time.zone.name).to eq current_user.timezone
        expect(@request.session[:timezone]).to eq current_user.timezone
      end

      it "should use session's value if is already set" do
        @request.session[:timezone] = "America/Chicago"
        get :index
        expect(Time.zone.name).to eq "America/Chicago"
        expect(@request.session[:timezone]).to eq "America/Chicago"
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
