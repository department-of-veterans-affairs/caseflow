class UpdateVocRehabName < Caseflow::Migration

  OLD_NAME = "Vocational Rehabilitation and Employment"
  NEW_NAME = "Veterans Readiness and Employment"

  def up
    BusinessLine.where(name: OLD_NAME).update(name: NEW_NAME)
  end

  def down
    BusinessLine.where(name: NEW_NAME).update(name: OLD_NAME)
  end
end
