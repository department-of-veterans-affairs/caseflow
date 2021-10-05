# frozen_string_literal: true

# Veterans Health Administration related seeds

module Seeds
  class VeteransHealthAdministration < Base
    PROGRAM_OFFICES = [
      "Community Care - Payment Operations Management",
      "Community Care - Veteran and Family Members Program",
      "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel",
      "Prosthetics",
      "Caregiver Appeals"
    ].freeze

    def seed!
      setup_camo_org
      setup_program_offices!
      create_visn_org_teams!
    end

    private

    def setup_camo_org
      regular_user = create(:user, full_name: "Greg CAMOUser Camo", css_id: "CAMOUSER")
      admin_user = create(:user, full_name: "Alex CAMOAdmin Camo", css_id: "CAMOADMIN")
      camo = VhaCamo.singleton
      camo.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, camo)
    end

    def setup_program_offices!
      PROGRAM_OFFICES.each { |name| VhaProgramOffice.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Stevie VhaProgramOffice Amana", css_id: "VHAPOUSER")
      admin_user = create(:user, full_name: "Channing VhaProgramOfficeAdmin Katz", css_id: "VHAPOADMIN")

      VhaProgramOffice.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end

    def create_visn_org_teams!
      regular_user = create(:user, full_name: "Stacy VISNUser Smith", css_id: "VISNUSER")
      admin_user = create(:user, full_name: "Betty VISNAdmin Rose", css_id: "VISNADMIN")

      Constants.VISN_ORG_NAMES.visn_orgs.name.each do |name|
        visn = VhaRegionalOffice.create!(name: name, url: name)
        visn.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, visn)
      end
    end
  end
end
