class ValidateForeignKeyOnCertificationCancellationToCertifications < Caseflow::Migration
  def change
    validate_foreign_key "certification_cancellations", column: "certification_id"
  end
end
