class UpdateSeniorCounsel < ActiveRecord::Migration[6.0]
  def change
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
end
