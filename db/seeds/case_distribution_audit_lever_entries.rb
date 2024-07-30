module Seeds
  class CaseDistributionAuditLeverEntries < Base
    def seed!
      create_entry_for_alternative_batch_size
    end

    private 

    def create_entry_for_alternative_batch_size
      lever = CaseDistributionLever.find_by_item("alternative_batch_size")
      user = CDAControlGroup.singleton.admins.first

      CaseDistributionAuditLeverEntry.create({
        user: user,
        case_distribution_lever: lever,
        previous_value: lever.value,
        update_value: "20"
      })
    end
  end
end