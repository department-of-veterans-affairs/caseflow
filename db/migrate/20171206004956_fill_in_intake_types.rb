class FillInIntakeTypes < ActiveRecord::Migration[5.1]
  def up
    # all intakes are Ramp Election Intakes right now. Set type accordingly.
    Intake.update_all(type: "RampElectionIntake")
  end
end
