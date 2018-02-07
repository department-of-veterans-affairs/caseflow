class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :issues do
    object.issues.map do |issue|
      {
        vacols_sequence_id: issue.vacols_sequence_id,
        levels: issue.levels,
        program: issue.program,
        type: issue.type,
        disposition: issue.disposition,
        close_date: issue.close_date,
        note: issue.note,
        id: issue.id,
        labels: issue.labels,
        codes: issue.codes
      }
    end
  end

  attribute :hearings do
    object.hearings.map do |hearing|
      {
        held_by: hearing.user.present? ? hearing.user.full_name : "",
        held_on: hearing.date,
        type: hearing.type
      }
    end
  end

  attribute :appellant_full_name do
    object.appellant_name
  end

  attribute :appellant_address do
    {
      address_line_1: object.appellant_address_line_1,
      address_line_2: object.appellant_address_line_2,
      city: object.appellant_city,
      state: object.appellant_state,
      zip: object.appellant_zip,
      country: object.appellant_country
    }
  end

  attribute :appellant_relationship
  attribute :veteran_full_name
  attribute :veteran_date_of_birth
  attribute :veteran_gender
  attribute :vbms_id
  attribute :vacols_id
  attribute :type
  attribute :aod
  attribute :docket_number
  attribute :number_of_documents_url

  attribute :power_of_attorney do
    # TODO: change this to use our more sophisticated poa data fetching mechanism
    object.representative
  end

  attribute :regional_office do
    {
      key: object.regional_office.key,
      city: object.regional_office.city,
      state: object.regional_office.state
    }
  end
end
