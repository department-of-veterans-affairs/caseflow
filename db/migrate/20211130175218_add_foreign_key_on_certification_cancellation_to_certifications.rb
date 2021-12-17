class AddForeignKeyOnCertificationCancellationToCertifications < Caseflow::Migration
  def change
    add_foreign_key "certification_cancellations", "certifications", validate: false
  end
end
