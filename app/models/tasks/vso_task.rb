class VsoTask < Task
  class << self
    def create_tasks_for_appeal!(appeal)
      vso_participant_ids = appeal.power_of_attorneys.map(&:participant_id)
      vsos_organizations = vso_participant_ids.each do |participant_id|
        vso_organization = Vso.find_by!(participant_id: participant_id)
        create(appeal: appeal, status: "in_progress", assigned_to: vso_organization)
      end
    end
  end
end
