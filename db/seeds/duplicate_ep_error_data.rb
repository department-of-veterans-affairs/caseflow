# rails runner db/seeds/duplicate_ep_data.rb to execute script.

# The loop continues generating new file numbers until it finds one that is not already in use in the Veteran table,
# at which point it breaks the loop and assigns that file number to the new Veteran record.
# This ensures that no duplicates are created, even if the script is run multiple times.
# This ensures that the file_number is unique.

 require 'faker'

ActiveRecord::Base.transaction do
  # Generate 1 HigherLevelReview record
  1.times do
    file_number = loop do
      random_file_number = "123#{Faker::Number.number(digits: 5)}"
      break random_file_number unless Veteran.exists?(file_number: random_file_number)
    end

    hlr = HigherLevelReview.create!(
      establishment_error: 'duplicateep',
      veteran_file_number: file_number,
    )

    end_product_establishments = EndProductEstablishment.create!(
      code: '030HLRNR',
      synced_status: %w[CAN CLR].shuffle.first,
      last_synced_at: [Date.today, 1.day.ago.to_date].sample,
      veteran: hlr.veteran,
      veteran_file_number: file_number)
    end

    #claimant = Claimant.create!(
      # add claimant attributes as needed
    #)

    #Todo: Create EPE
    puts "Created HigherLevelReview with ID #{hlr.id}, Veteran with ID #{hlr.veteran.id}, and EndProduct with ID #{end_product.id}"
  end

  # Generate 1 SupplementalClaim record
  #1.times do
    #file_number = loop do
      #random_file_number = "123#{Faker::Number.number(digits: 5)}"
      #break random_file_number unless Veteran.exists?(file_number: random_file_number)
    #end

    #sc = SupplementalClaim.create!(
      #establishment_error: 'duplicateep',
    #)

    #claimant = Claimant.create!(
      # add claimant attributes as needed
    #)

    #end_product_establishments = EndProductEstablishment.create!(
      #claimant: claimant,
      #code: '040',
      #status_type_code: %w[CAN CLR].shuffle.first,
      #last_action_date: [Date.today, 1.day.ago.to_date].sample,
      #veteran: sc.veteran
    #)

    #puts "Created SupplementalClaim with ID #{sc.id}, Veteran with ID #{sc.veteran.id} and EndProduct with ID #{end_product.id}"
  #end
end
