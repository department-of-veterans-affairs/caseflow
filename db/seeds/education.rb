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
      regular_user = User.find_or_initialize_by(css_id: "EMOUSER")
      unless regular_user.persisted?
        regular_user.update!(full_name: "Paul EMOUser EMO")
      end

      admin_user = User.find_or_initialize_by(css_id: "EMOADMIN")
      unless admin_user.persisted?
        admin_user.update!(full_name: "Julie EMOAdmin EMO")
      end

      emo = EducationEmo.singleton
      emo.add_user(regular_user)
      OrganizationsUser.make_user_admin(admin_user, emo)
    end

    def setup_rpo_orgs!
      RPOS.each do |name|
        org = EducationRpo.find_or_initialize_by(url: name.parameterize)
        unless org.persisted?
          org.update!(name: name)
        end
      end

      regular_user = User.find_or_initialize_by(css_id: "EDURPOUSER")
      unless regular_user.persisted?
        regular_user.update!(full_name: "Peter EDURPOUSER Campbell")
      end

      admin_user = User.find_or_initialize_by(css_id: "EDURPOADMIN")
      unless admin_user.persisted?
        admin_user.update!(full_name: "Samuel EDURPOADMIN Clemens")
      end

      EducationRpo.all.each do |org|
        org.add_user(regular_user)
        OrganizationsUser.make_user_admin(admin_user, org)
      end
    end
  end
end
