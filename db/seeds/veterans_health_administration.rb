# frozen_string_literal: true

# Veterans Health Administration related seeds

module Seeds
  # rubocop:disable Metrics/MethodLength
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
      setup_program_offices!
      create_visn_org_teams
    end

    private

    def setup_program_offices!
      PROGRAM_OFFICES.each { |name| VhaProgramOffice.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Stevie VhaProgramOffice Amana", css_id: "VHAPOUSER")
      admin_user = create(:user, full_name: "Channing VhaProgramOfficeAdmin Katz", css_id: "VHAPOADMIN")

      VhaProgramOffice.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end

    def visn_orgs
      [
        {
          name: "VA New England Healthcare System",
          url: "VA New England Healthcare System",
          type: "VhaRegionalOffice"
        },
        {
          name: "New York/New Jersey VA Health Care Network",
          url: "New York/New Jersey VA Health Care Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Healthcare",
          url: "VA Healthcare",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Capitol Health Care Network",
          url: "VA Capitol Health Care Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Mid-Atlantic Health Care Network",
          url: "VA Mid-Atlantic Health Care Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Southeast Network",
          url: "VA Southeast Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Sunshine Healthcare Network",
          url: "VA Sunshine Healthcare Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA MidSouth Healthcare Network",
          url: "VA MidSouth Healthcare Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Healthcare System",
          url: "VA Healthcare System",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Great Lakes Health Care System",
          url: "VA Great Lakes Health Care System",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Heartland Network",
          url: "VA Heartland Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "South Central VA Health Care Network",
          url: "South Central VA Health Care Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Heart of Texas Health Care Network",
          url: "VA Heart of Texas Health Care Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "Rocky Mountain Network",
          url: "Rocky Mountain Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "Northwest Network",
          url: "Northwest Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "Sierra Pacific Network",
          url: "Sierra Pacific Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "Desert Pacific Healthcare Network",
          url: "Desert Pacific Healthcare Network",
          type: "VhaRegionalOffice"
        },
        {
          name: "VA Midwest Health Care Network",
          url: "VA Midwest Health Care Network",
          type: "VhaRegionalOffice"
        }
      ]
    end

    def create_visn_org_teams
      visn_orgs.each do |org|
        org[:url]&.parameterize&.dasherize
        VhaRegionalOffice.create!(org)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
