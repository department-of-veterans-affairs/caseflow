# frozen_string_literal: true

feature "CamoQueue", :all_dbs do
  context "user with case details role " do
    let(:organization) { VhaCamo.singleton }
    let(:camo_user) { User.authenticate!(roles: ["Admin Intake"]) }

    before do
      organization.add_user(camo_user)
      camo_user.reload
      visit "/organizations/#{organization.url}"
    end

    scenario "attorney user in an organization with assigned tasks" do
      expect(find("h1")).to have_content("VHA CAMO cases")
    end
  end
end
