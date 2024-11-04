# frozen_string_literal: true

class Remediations::DuplicatePersonRemediationService
  def initialize(person_ids)
    @person_ids = person_ids
  end

  def remediate!
    # in this method we will implement some logic to find and delete any duplicate persons
    # will check by ssn
    fix_duplicates
  end

  def fix_duplicates
    updated_people.each do |person|
      find_and_update_records(person)
    end
  end

  def find_and_update_records(person)
    dup_persons = Person.where(ssn: person.ssn)
    og_person = dup_persons.find(person.id)
    dup_person = dup_persons.where.not(id: person.id).first
    find_and_update_claimants(dup_person, og_person)
    # find_and_update_decision_issues()

    # destroy dup_person
  end

  def updated_people
    @person_ids.map do |id|
      Person.find_by(id: id)
    end
  end

  def find_and_update_claimants(dup_person, og_person)
    claimants = Claimant.where(participant_id: dup_person.participant_id)

    claimants.each do |claimant|
      claimant.update!(participant_id: og_person.participant_id)
    end
  end

  # def update_records_for_person(dup_person, og_person)
  #   find_and_update_claimants(dup_person, og_person)
  #   # find_and_update_decision_issues(dup_person, og_person)
  #   # find_and_update_request_issues(dup_person, og_person)
  # end
end


# hash = {
#   og_person_id: 1234,
#   dup_person_id: 2234
# }

# # array of claimants to update


# def claimants_to_update(dup_person)
#   dup_person = Person.find_by(id: hash[:dup_person_id])
#   Claimant.where(participant_id: dup_person.particpant_id)
# end


# def update_claimants(claimants, hash)
#   og_person = Person.find_by(id: hash[:og_person_id])
#   claimants.map do |c|
#     claimant.update!(participant_id: og_person.participant_id)
#   end
# end

