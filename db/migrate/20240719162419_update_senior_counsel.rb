class UpdateSeniorCounsel < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.transaction do
      # Use direct SQL update to bypass STI mechanism
      ActiveRecord::Base.connection.execute(
        "UPDATE organizations SET type = 'SupervisorySeniorCounsel' WHERE name = 'Supervisory Senior Council'"
      )

      # Fetch the updated organization
      organization = Organization.find_by(name: SupervisorySeniorCounsel.first.name)

      # Update attributes
      organization.update!(
        name: "Supervisory Senior Counsel",
        url: "supervisory-senior-counsel"
      )
    rescue StandardError => error
      puts "Error updating names, types, and URLs: #{error.message}"
      raise ActiveRecord::Rollback
    end
  end
  def down
    ActiveRecord::Base.transaction do

      # Revert type update using direct SQL
      ActiveRecord::Base.connection.execute(
        "UPDATE organizations SET type = 'Supervisory Senior Council' WHERE name = 'Supervisory Senior Counsel'"
      )

      # Revert name and url update
      organization = Organization.find_by(name: SupervisorySeniorCounsel.first.name)
      organization.update!(
        name: "Supervisory Senior Council",
        url: "supervisory-senior-council"
      )
    rescue StandardError => error
      puts "Error reverting names, types, and URL: #{error.message}"
      raise ActiveRecord::Rollback
    end
  end
end
