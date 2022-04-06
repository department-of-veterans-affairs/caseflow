# frozen_string_literal: true

# Education related seeds

module Seeds
    class Education < Base
      REGIONAL_PROCESSING_OFFICES = [
        "Buffalo RPO - Buffalo Regional Processing Office",
        "Central Office RPO - Central Office Regional Processing Office",
        "Muskogee RPO - Muskogee Regional Processing Office",
      ].freeze
  
      def seed!
        #setup_emo_org
        setup_regional_processing_offices!
      end
  
      private

      #def setup_emo_org
      #end

  
      def setup_regional_processing_offices!
        REGIONAL_PROCESSING_OFFICES.each { |name| EduRegionalProcessingOffice.create!(name: name, url: name) }
  
        regular_user = create(:user, full_name: "Peter EDURPOUSER Campbell", css_id: "EDURPOUSER") 
        admin_user = create(:user, full_name: "Samuel EDURPOADMIN Clemens", css_id: "EDURPOADMIN") 
  
        EduRegionalProcessingOffice.all.each do |org|
          org.add_user(regular_user)
          OrganizationsUser.make_user_admin(admin_user, org)
        end
      end
  
      
    end
  end