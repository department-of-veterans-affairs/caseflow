class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :issues do
    object.issues.map do |issue|
      {
        close_date: issue.close_date,
        codes: issue.codes,
        disposition: issue.disposition,
        id: issue.id,
        labels: issue.labels,
        note: issue.note,
        vacols_sequence_id: issue.vacols_sequence_id
      }
    end
  end

  attribute :hearings do
    object.hearings.map do |_hearing|
      {
        held_by: object.user.full_name,
        held_on: object.date,
        type: object.type
      }
    end
  end

  attribute :veteran_full_name
  attribute :vbms_id
  attribute :vacols_id
  attribute :type
  attribute :aod

  attribute :regional_office do
    {
      key: object.regional_office.key,
      city: object.regional_office.city,
      state: object.regional_office.state
    }
  end
end
