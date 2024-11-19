# frozen_string_literal: true

# Education related seeds

module Seeds
  class Education < Base
    RPOS = [
      "Buffalo RPO",
      "Central Office RPO",
      "Muskogee RPO"
    ].freeze

    def seed!
      setup_emo_org
      setup_rpo_orgs!
    end

    private

    def setup_emo_org
      regular_user = create(:user, full_name: "Paul EMOUser EMO", css_id: "EMOUSER")
      admin_user = create(:user, full_name: "Julie EMOAdmin EMO", css_id: "EMOADMIN")
      emo = EducationEmo.singleton
      emo.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, emo)
    end

    def setup_rpo_orgs!
      RPOS.each { |name| EducationRpo.create!(name: name, url: name) }

      regular_user = create(:user, full_name: "Peter EDURPOUSER Campbell", css_id: "EDURPOUSER")
      admin_user = create(:user, full_name: "Samuel EDURPOADMIN Clemens", css_id: "EDURPOADMIN")

      EducationRpo.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end
  end
end
