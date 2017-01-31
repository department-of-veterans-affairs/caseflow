namespace :tasks do
  desc "Update tasks to have an aasm_state"
  task set_task_aasm_state: :environment do
    EstablishClaim.all.each do |establish_claim|
      establish_claim.aasm_state = "completed"
      establish_claim.save
    end
  end
end
