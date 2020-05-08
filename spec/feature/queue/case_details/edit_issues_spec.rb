# frozen_string_literal: true

RSpec.feature "Edit Issues", :all_dbs do
  shared_examples "can NOT view the 'Correct Issues' link" do
    it "does not show 'Correct Issues' link" do
      visit("/queue/appeals/#{appeal.uuid}")

      expect(page).not_to have_content(COPY::CORRECT_REQUEST_ISSUES_LINK)
    end
  end

  shared_examples "can view the 'Correct Issues' link" do
    it "shows 'Correct Issues' link" do
      visit("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content(COPY::CORRECT_REQUEST_ISSUES_LINK)
    end
  end

  let(:user) { create(:user, station_id: User::BOARD_STATION_ID) }
  let(:appeal) { create(:appeal) }

  before { User.authenticate!(user: user) }

  context "for a misc user" do
    it_behaves_like "can NOT view the 'Correct Issues' link"
  end

  context "for an intake user" do
    before { BvaIntake.singleton.add_user(user) }
    it_behaves_like "can view the 'Correct Issues' link"
  end

  context "for an intake user" do
    before { CaseReview.singleton.add_user(user) }
    it_behaves_like "can view the 'Correct Issues' link"
  end

  context "for a judge" do
    let!(:user_staff) { create(:staff, :judge_role, sdomainid: user.css_id) }
    let!(:hearing) { create(:hearing, appeal: appeal, judge: user) }

    context "that is assigned to a hearing" do
      it_behaves_like "can view the 'Correct Issues' link"
    end

    context "that is not assigned to a hearing" do
      before { hearing.update!(judge: create(:user)) }

      it_behaves_like "can NOT view the 'Correct Issues' link"
    end
  end
end
