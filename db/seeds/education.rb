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
  
        regular_user = create(:user, full_name: "Stevie EduRPOUser Amana", css_id: "VHAPOUSER") # Need CSSID from Stakeholders, unsure about user naming conventions? See line
        admin_user = create(:user, full_name: "Channing EduRPOAdmin Katz", css_id: "VHAPOADMIN") # Need CSSID from Stakeholders, unure about admin naming conventions? See line
  
        EduRegionalProcessingOffice.all.each do |org|
          org.add_user(regular_user)
          OrganizationsUser.make_user_admin(admin_user, org)
        end
      end
  
      
    end
  end