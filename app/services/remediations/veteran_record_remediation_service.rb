# frozen_string_literal: true

class Remediations::VeteranRecordRemediationService
  def intitialize(vet_ids)
    @vet_ids = vet_ids
  end

  def remediate
    # in this method we will implement some logic to find and update records associated
    # with veterans that have updated file numbers
    # will check by file number and possibly other
  end
end
