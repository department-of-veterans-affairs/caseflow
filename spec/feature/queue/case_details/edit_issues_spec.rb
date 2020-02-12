# frozen_string_literal: true

RSpec.feature "Edit Issues", :all_dbs do
  before do
    FeatureToggle.enable!(:allow_judge_edit_issues)
  end

  after do
    FeatureToggle.disable!(:allow_judge_edit_issues)
  end

  context "for a judge" do
    let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }

    before do
      User.authenticate!(user: judge)
    end

    context "that is assigned to a hearing" do
      let(:appeal) { create(:appeal) }
      let!(:hearing) { create(:hearing, appeal: appeal, judge: judge) }

      it "can view the 'Correct Issues' link" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_LINK)
      end
    end

    context "that is not assigned to a hearing" do
      let(:appeal) { create(:appeal) }
      let!(:hearing) do
        create(
          :hearing,
          appeal: appeal,
          judge: create(:user, station_id: User::BOARD_STATION_ID)
        )
      end

      it "can NOT view the 'Correct Issues' link" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to_not have_content(COPY::CORRECT_REQUEST_ISSUES_LINK)
      end
    end
  end
end
