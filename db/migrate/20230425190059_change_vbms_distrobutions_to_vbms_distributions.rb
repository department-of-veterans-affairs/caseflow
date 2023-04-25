class ChangeVbmsDistrobutionsToVbmsDistributions < Caseflow::Migration
  def change
    safety_assured { rename_table :vbms_distrobutions, :vbms_distributions }
  end
end
