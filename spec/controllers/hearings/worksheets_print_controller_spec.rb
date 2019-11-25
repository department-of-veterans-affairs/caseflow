# frozen_string_literal: true

RSpec.describe Hearings::WorksheetsPrintController, :postgres, type: :controller do
  describe "GET print view of worksheet" do
    context "user with invalid roles" do
      [
        %w[],
        %w[VSO],
        %w[Invalid],
        %w[Mail\ Intake]
      ].each do |roles|
        it "returns 302 status code and redirects with invalid roles #{roles}" do
          User.authenticate!(roles: roles)
          get :index
          expect(response.status).to eq 302
          expect(response).to redirect_to("/unauthorized")
        end
      end
    end

    context "user with valid roles" do
      [
        %w[Reader],
        %w[Hearing\ Prep],
        %w[Edit\ HearSched],
        %w[Build\ HearSched],
        %w[Reader Hearing\ Prep],
        %w[System\ Admin]
      ].each do |roles|
        it "returns 200 status code with valid roles #{roles}" do
          User.authenticate!(roles: roles)
          get :index
          expect(response.status).to eq 200
        end
      end
    end
  end
end
