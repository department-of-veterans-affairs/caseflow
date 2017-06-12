# spec/controllers/hearings_dockets_controller_spec.rb
require "rails_helper"

RSpec.describe Hearings::DocketsController, type: :controller do
  let!(:current_user) { User.authenticate! }

  describe "Responds to #show" do
    context "with redirect" do
      it "when the date is wrongly formatted" do
        get :show, "id" => "0000-10-10"
        expect(response).to have_http_status(:redirect)
        get :show, "id" => "2017-00-10"
        expect(response).to have_http_status(:redirect)
        get :show, "id" => "2017-10-00"
        expect(response).to have_http_status(:redirect)
      end

      it "when there is no docket for the given date" do
        get :show, "id" => "2017-10-10"
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with success" do
      let!(:current_user) do
        User.authenticate!(roles: ["Hearings"])
      end

      let(:date) { Time.zone.now }

      let!(:hearing) do
        Generators::Hearing.build(
          user: current_user,
          date: date,
          type: "video"
        )
      end

      it "when a docket is retrieved" do
        get :show, "id" => "#{date.year}-#{date.month}-#{date.day}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
