# frozen_string_literal :true

# create correspondence seeds
module Seeds
  class Correspondence < Base
    def seed!
      #create_correspondence_users
      create_correspondences_1
      create_correspondences_2
      create_correspondences_3
      #create_correspondence_tasks_1
    end

    private

=begin     def create_correspondence_users
      ["Mail Intake", "Admin Intake"].each do |role|
        # do not try to recreate when running seed file after inital seed
        next if User.find_by_css_id("#{role.tr(' ', '')}_LOCAL".upcase)

        create(:user,
               css_id: "#{role.tr(' ', '')}_LOCAL",
               roles: [role],
               station_id: "101",
               full_name: "Arthur Local #{role} Pendragon")
      end
    end
=end

    def create_correspondences_1
      params = { first_name: "Adam", last_name: "West" }
      params[:file_number] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      params[:participant_id] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      veteran = create(
                  :veteran,
                  params)
      10.times do
        create(:correspondence,
               veteran_id: veteran.participant_id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )
      end
    end

    def create_correspondences_2
      params = { first_name: "Michael", last_name: "Keaton" }
      params[:file_number] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      params[:participant_id] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      veteran = create(
                  :veteran,
                  params)
      8.times do
        create(:correspondence,
               veteran_id: veteran.participant_id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )

      end
    end

    def create_correspondences_3
      params = { first_name: "Christian", last_name: "Bale" }
      params[:file_number] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      params[:participant_id] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      veteran = create(
                  :veteran,
                  params)
      25.times do
        create(:correspondence,
               veteran_id: veteran.participant_id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )
      end
    end

=begin
    def create_correspondence_tasks_1
      5.times do
        veteran = Veteran.find_by(file_number: 66_555_444)
        epe = create(:end_product_establishment, veteran_file_number: veteran.file_number)

        #Create Any Necessary Tasks [TO-DO, Edit as needed]
        3.times do
          let(:root_task) { create(:root_task) }
          let(:mail_user) { create(:user) }
          let (:mail_grandparent_organization_task) do
            create(:aod_motion_mail_task, assigned_to: MailTeam.singleton, parent: root_task)
          end
          let!(:mail_parent_organization_task) do
            create(:aod_motion_mail_task, assigned_to: MailTeam.singleton, parent: mail_grandparent_organization_task)
          end
          let!(:mail_task) do
            create(:aod_motion_mail_task, assigned_to: mail_user, parent: mail_parent_organization_task)
          end
      end
    end
=end
  end
end
