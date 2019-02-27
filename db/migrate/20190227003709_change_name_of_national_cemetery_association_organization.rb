class ChangeNameOfNationalCemeteryAssociationOrganization < ActiveRecord::Migration[5.1]
  def change
    Organization.find_by(url:"nca")&.update!(name: "National Cemetery Administration")
  end
end
