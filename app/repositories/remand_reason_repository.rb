class RemandReasonRepository
  # :nocov:
  def self.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
    BusinessMetrics.record(service: :queue, name: "create_remand_reasons")
    VACOLS::RemandReason.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
  end

  def self.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs)
    BusinessMetrics.record(service: :queue, name: "delete_remand_reasons")
    VACOLS::RemandReason.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs)
  end

  def self.load_remands_from_vacols(vacols_id, vacols_sequence_id)
    VACOLS::RemandReason.load_remand_reasons(vacols_id, vacols_sequence_id).map do |reason|
      {
        code: reason.rmdval,
        after_certification: reason.rmddev.eql?("R2")
      }
    end
  end

  def self.update_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
    existing_remand_reasons = VACOLS::RemandReason.load_remand_reasons(vacols_id, vacols_sequence_id)
      .pluck(:rmdval)

    reasons_to_delete = existing_remand_reasons - remand_reasons.pluck(:rmdval)
    reasons_to_create = remand_reasons.reject { |r| existing_remand_reasons.include? r[:rmdval] }
    reasons_to_update = remand_reasons.reject { |r| reasons_to_create.pluck(:rmdval).include? r[:rmdval] }

    delete_remand_reasons!(vacols_id, vacols_sequence_id, rmdval: reasons_to_delete) unless reasons_to_delete.empty?
    create_remand_reasons!(vacols_id, vacols_sequence_id, reasons_to_create) unless reasons_to_create.empty?

    unless reasons_to_update.empty?
      BusinessMetrics.record(service: :queue, name: "update_remand_reasons")
      VACOLS::RemandReason.update_remand_reasons!(vacols_id, vacols_sequence_id, reasons_to_update)
    end
  end
  # :nocov:

  def self.update_remand_reasons(record, issue_attrs)
    args = [issue_attrs[:vacols_id], issue_attrs[:vacols_sequence_id]]

    unless Constants::VACOLS_DISPOSITIONS_BY_ID[issue_attrs[:disposition]].eql? "Remanded"
      delete_remand_reasons!(*args)
      return
    end

    remand_reasons = RemandReasonMapper.convert_to_vacols_format(
      issue_attrs[:vacols_user_id],
      issue_attrs[:remand_reasons]
    )
    args.push(remand_reasons)

    if record.issdc.eql? "3"
      update_remand_reasons!(*args)
    else
      create_remand_reasons!(*args)
    end
  end
end
