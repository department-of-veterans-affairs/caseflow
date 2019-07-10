# frozen_string_literal: true

RSpec.describe Hearings::HearingDayPrintController, type: :controller, focus: true do
  describe "GET print view of daily docket" do
    let(:hearing_day) { create(:hearing_day) }

    context "user with invalid roles" do
      [
        %w[],
        %w[Invalid],
        %w[Mail\ Intake]
      ].each do |roles|
        let!(:user) { User.authenticate!(roles: roles) }

        it "returns 302 status code and redirects with invalid roles #{roles}" do
          get :index, { params: { id: hearing_day.id }}
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
        %w[System\ Admin],
        %w[VSO],
        %w[RO ViewHearSched]
      ].each do |roles|
        let!(:user) { User.authenticate!(roles: roles) }

        it "returns 200 status code with valid roles #{roles}" do
          get :index, { params: { id: hearing_day.id }}
          expect(response.status).to eq 200
        end
      end
    end
  end
end
