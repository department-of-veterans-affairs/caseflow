class FillInIntakeTypes < ActiveRecord::Migration
  def up
    # all intakes are Ramp Election Intakes right now. Set type accordingly.
    Intake.update_all(type: "RampElectionIntake")
  end
end
