class Fakes::RemandReasonRepository
  def self.create_remand_reasons!(_vacols_id, _vacols_sequence_id, _remand_reasons)
    []
  end

  def self.delete_remand_reasons!(_vacols_id, _vacols_sequence_id, **_kwargs)
    []
  end

  def self.load_remands_from_vacols(_vacols_id, _vacols_sequence_id)
    []
  end

  def self.update_remand_reasons!(_vacols_id, _vacols_sequence_id, _remand_reasons)
    []
  end

  def self.update_remand_reasons(_record, _issue_attrs)
    []
  end
end
