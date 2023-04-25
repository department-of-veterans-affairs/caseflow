class ChangeVbmsCommunicationPackages < Caseflow::Migration
  def change
    change_column_null(:vbms_communication_packages, :updated_at, true)
  end
end
