# frozen_string_literal: true

class Remediations::DuplicatePersonRemediationService
  def intitialize(person_ids)
    @person_ids = person_ids
  end

  def remdiate
    # in this method we will implement some logic to find and delete any duplicate persons
    # will check by ssn
  end
end
