# frozen_string_literal: true

namespace :db do
    desc "Update names, types, and URLs in the users table"
    task update_senior_counsel: :environment do
      ActiveRecord::Base.transaction do
        begin
            organization = Organization.find_by(type: "SupervisorySeniorCounsel")

            puts organization

            organization.update!(
              name: "Supervisory Senior Counsel",
              url: "supervisory-senior-counsel"
            )
            puts "Updated name to #{organization.name} and URL #{organization.url}"
          end

        puts "Update complete."
      rescue StandardError => error
        puts "Error updating names and URLs: #{error.message}"
        raise ActiveRecord::Rollback
      end
    end
  end
