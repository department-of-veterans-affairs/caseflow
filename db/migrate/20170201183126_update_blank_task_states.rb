class UpdateBlankTaskStates < ActiveRecord::Migration
  def change
    EstablishClaim.where(aasm_state: nil).each do |establish_claim|
      establish_claim.aasm_state = "completed"
      establish_claim.save
    end
  end
end
