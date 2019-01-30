require "rails_helper"

RSpec.feature "Hearing Schedule Daily Docket" do
  context "Hearing details is editable for a hearings management user" do
    let!(:current_user) do
      OrganizationsUser.add_user_to_organization(create(:hearings_management), HearingsManagement.singleton)
      User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
    end
    let!(:hearing) { create(:hearing) }

    scenario "User can update fields" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
    end
  end

  context "Hearing details is not editable for a non-hearings management user" do
    let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"]) }
    let!(:hearing) { create(:hearing) }

    scenario "User cannot update fields" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
    end
  end
end
