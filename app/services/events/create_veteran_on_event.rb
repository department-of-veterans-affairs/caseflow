# frozen_string_literal: true

# Module that will be utilized by Events::DecisionReviewCreated to create a new Veteran
# when an Event is received and that specific Veteran does not already exist in Caseflow
module Events::CreateVeteranOnEvent
  def handle_veteran_creation_on_event(event, headers, veteran)
    unless veteran_exist?(veteran_ssn)
      create_backfill_veteran(event, headers)
    else
      Veteran.find_by(ssn: veteran_ssn)
    end
  end

  def veteran_exist?(veteran_ssn)
    User.where(ssn: veteran_ssn).exists?
  end

  def create_backfill_veteran(event, headers, veteran)
    # Create Veteran without calling BGS
    vet = Veteran.create(
      file_number: veteran_file_number,
      ssn: veteran_ssn,
      first_name: headers["X-VA-Vet-First-Name"],
      last_name: headers["X-VA-Vet-Last-Name"],
      middle_name: headers["X-VA-Vet-Middle-Name"],
      participant_id: veteran.participant_id,
      bgs_last_synced_at: veteran.bgs_last_synced_at,
      name_suffix: veteran.name_suffix,
      date_of_death: veteran.date_of_death
    )
    # Update the CF cache
    if vet.cached_attributes_updatable?
      vet.update_cached_attributes!
    end
    # create Event record indicating this is a backfilled Veteran
    EventRecord.create!(event: event, backfill_record: vet)

    return vet
  end

  def veteran_ssn
    @veteran_ssn ||= headers["X-VA-Vet-SSN"].presence
  end

  def veteran_file_number
    @file_number ||= headers["X-VA-FILE-NUMBER"].presence
  end
end
