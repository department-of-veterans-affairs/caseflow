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
    object.hearings.map do |hearing|
      {
        held_by: hearing.user.full_name,
        held_on: hearing.date,
        type: hearing.type
      }
    end
  end

  attribute :veteran_full_name
  attribute :vbms_id
  attribute :vacols_id
  attribute :type
  attribute :aod

  attribute :document_count do
    object.saved_documents.length
  end

  attribute :regional_office do
    {
      key: object.regional_office.key,
      city: object.regional_office.city,
      state: object.regional_office.state
    }
  end
end
