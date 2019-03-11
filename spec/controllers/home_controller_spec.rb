# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
  describe "GET /" do
    context "when visitor is not logged in" do
      let!(:current_user) { nil }
      it "should redirect to /help" do
        get :index
        expect(response.status).to eq 302
        expect(URI.parse(response.location).path).to eq("/help")
      end
    end

    context "when visitor is logged in, does not have a personal queue, nor case search access" do
      let!(:current_user) { User.authenticate! }

      it "should redirect to /help" do
        get :index
        expect(response.status).to eq 302
        expect(URI.parse(response.location).path).to eq("/help")
      end
    end

    context "when visitor is logged in, does not have a personal queue but does have case search access" do
      let!(:current_user) { User.authenticate! }

      before do
        FeatureToggle.enable!(:case_search_home_page, users: [current_user.css_id])
      end

      after do
        FeatureToggle.disable!(:case_search_home_page, users: [current_user.css_id])
      end

      it "should land at /" do
        get :index
        expect(response.status).to eq 200
      end
    end
  end
end
