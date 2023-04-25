class ChangeVbmsDistrobutionDestinationsToVbmsDistributionDestinations < Caseflow::Migration
  def change
    safety_assured { rename_table :vbms_distrobution_destinations, :vbms_distribution_destinations }
  end
end
