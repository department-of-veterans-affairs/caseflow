class AddOriginalVacolsRequestTypeToLegacyHearing < Caseflow::Migration
  def change
    add_column :legacy_hearings, :original_vacols_request_type, :string, comment: "The original request type of the hearing in VACOLS, before it was changed to Virtual"
  end
end
