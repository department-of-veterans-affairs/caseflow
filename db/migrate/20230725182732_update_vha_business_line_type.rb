class UpdateVhaBusinessLineType < Caseflow::Migration
  def up
    # Update the business line record with url = 'vha' to set their type to 'VhaBusinessLine'
    BusinessLine.where(url: 'vha').update_all(type: 'VhaBusinessLine')
  end

  def down
    # Revert the business line record with url = 'vha' to set their type back to 'BusinessLine'
    BusinessLine.where(url: 'vha').update_all(type: 'BusinessLine')
  end
end
