# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "support/database_cleaner"
require "rails_helper"

RSpec.feature "DeathDismissalAction", :all_dbs do

  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let(:colocated_admin) { create(:user) }
  let(:colocated_user) { create(:user) }
  let(:correspondent) { create(:correspondent, sfnod: 4.days.ago) }
  let!(:vacols_case) { create(:case, correspondent: correspondent) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  before do
    OrganizationsUser.make_user_admin(colocated_admin, Colocated.singleton)
    OrganizationsUser.add_user_to_organization(colocated_user, Colocated.singleton)
    User.authenticate!(user: colocated_admin)
  end

  describe "Death dismissal" do
    context "when a legacyAppeal is assigned to VLJ Support" do
      context "and the case has a Notice of Death Date set" do
        context "and the user is a VLJ Support Admin" do
          let!(:colocated_task) do
            org_task = create(:colocated_task, assigned_by: attorney, appeal: appeal)
          end

          it "can perform a death dismissal" do
            visit("queue/appeals/#{appeal.external_id}")

            prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
            text = Constants.TASK_ACTIONS.DEATH_DISMISSAL.label
            click_dropdown(prompt: prompt, text: text)

            expect(page).to have_content(COPY::DEATH_DISMISSAL_MODAL_TITLE)
            click_button(COPY::DEATH_DISMISSAL_MODAL_SUBMIT)

            expect(page).to have_content(COPY::DEATH_DISMISSAL_SUCCESS_DETAIL)
          end

        end
      end
    end
  end

  # Colocated User can see, and select, Death Dismissal, confirm via modal, and be
  # returned to their work queue.
 
end
