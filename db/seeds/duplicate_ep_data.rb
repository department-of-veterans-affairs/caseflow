# rails runner db/seeds/duplicate_ep_data.rb to execute script.

ActiveRecord::Base.transaction do
  # Generate 5 HigherLevelReview records
  1.times do
    hlr = HigherLevelReview.create!(
      establishment_error: 'duplicateep',
      veteran: Veteran.create!(
        file_number: '123546789',
        first_name: 'John',
        last_name: 'Doe',
        ssn: '123_54_6789',
      )
    )
    claimant = Claimant.create!(
      # add claimant attributes as needed
    )
    end_product = EndProduct.create!(
      claimant: claimant,
      claim_type_code: '030',
      status_type_code: %w[CAN CLR].shuffle.first,
      last_action_date: [Date.today, 1.day.ago.to_date].sample,
      veteran: hlr.veteran
    )
    puts "Created HigherLevelReview with ID #{hlr.id}, Veteran with ID #{hlr.veteran.id}, EndProduct with ID #{end_product.id}, and Claimant with ID #{claimant.id}"
  end

  # Generate 5 SupplementalClaim records
  1.times do
    sc = SupplementalClaim.create!(
      establishment_error: 'duplicateep',
      veteran: Veteran.find_or_create_by_file_number(
        file_number: '123564789',
        first_name: 'Jane',
        last_name: 'Doe',
        ssn: '123_56_4789',
      )
    )
    claimant = Claimant.create!(
      # add claimant attributes as needed
    )
    end_product = EndProduct.create!(
      claimant: claimant,
      claim_type_code: '040',
      status_type_code: %w[CAN CLR].shuffle.first,
      last_action_date: [Date.today, 1.day.ago.to_date].sample,
      veteran: sc.veteran
    )
    puts "Created SupplementalClaim with ID #{sc.id}, Veteran with ID #{sc.veteran.id}, EndProduct with ID #{end_product.id}, and Claimant with ID #{claimant.id}"
  end
end
