# frozen_string_literal: true

namespace :db do
  desc "Update names, types, and URLs in the users table"
  task update_senior_counsel: :environment do
    ActiveRecord::Base.transaction do
      begin
          # Use a direct SQL update to bypass STI mechanism
          ActiveRecord::Base.connection.execute(
            "UPDATE organizations SET type = 'SupervisorySeniorCounsel' WHERE name = 'Supervisory Senior Council'"
          )

          organization = Organization.find_by(type: SupervisorySeniorCounsel.first.type)

          organization.update!(
            name: "Supervisory Senior Counsel",
            url: "supervisory-senior-counsel"
          )
          puts "Updated name to #{organization.name}, type to #{organization.type}, and URL #{organization.url}"
        end

      puts "Update complete."
    rescue StandardError => error
      puts "Error updating names, types, and URLs: #{error.message}"
      raise ActiveRecord::Rollback
    end
  end
end
