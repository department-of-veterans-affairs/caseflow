# frozen_string_literal: true

class RemandReasonRepository
  def self.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
    BusinessMetrics.record(service: :queue, name: "create_remand_reasons")
    VACOLS::RemandReason.create_remand_reasons!(vacols_id, vacols_sequence_id, remand_reasons)
  end

  def self.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs)
    BusinessMetrics.record(service: :queue, name: "delete_remand_reasons")
    VACOLS::RemandReason.delete_remand_reasons!(vacols_id, vacols_sequence_id, **kwargs)
  end

  # Returns remand reasons grouped by brieff.bfkey and the issue sequence id. For example:
  # {"465400"=>{},
  #  "1074694"=>
  #   {6=>
  #     [{:code=>"1E", :post_aoj=>false},
  #      {:code=>"1B", :post_aoj=>false}],
  #    8=>
  #     [{:code=>"1B", :post_aoj=>false},
  #      {:code=>"1C", :post_aoj=>false},
  #      {:code=>"1E", :post_aoj=>false}],
  #   },
  #  "1014716"=>
  #   {1=>
  #     [{:code=>"1A", :post_aoj=>true},
  #      {:code=>"3D", :post_aoj=>true}]}
  #  }
  def self.load_remand_reasons_for_appeals(vacols_ids)
    # `rmdissseq` will be null for remand reasons on appeals before 1999.
    # See https://github.com/department-of-veterans-affairs/dsva-vacols/issues/13
    # If we ever want to display remand reasons for appeals before then,
    # we'll need to refactor to pass remand reasons down at the appeal level on the frontend.
    reason_groups = VACOLS::RemandReason.load_remand_reasons_for_appeals(vacols_ids).group_by(&:rmdkey)

    vacols_ids.each_with_object({}) do |vacols_id, obj|
      obj[vacols_id] ||= {}

      next unless reason_groups[vacols_id]

      reason_group = reason_groups[vacols_id].group_by(&:rmdissseq)
      reason_group.each do |issue_sequence_id, reasons|
        formatted_reasons = reasons.map do |reason|
          remand_reason_from_vacols_remand_reason(reason)
        end

        obj[vacols_id][issue_sequence_id] = formatted_reasons
      end
    end
  end

  # :nocov:
  def self.remand_reason_from_vacols_remand_reason(reason)
    {
      code: reason.rmdval,
      post_aoj: reason.rmddev.eql?("R2")
    }
  end

  def self.load_remands_from_vacols(vacols_id, vacols_sequence_id)
    VACOLS::RemandReason.load_remand_reasons(vacols_id, vacols_sequence_id).map do |reason|
      remand_reason_from_vacols_remand_reason(reason)
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
    disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[record.issdc]
    new_disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[issue_attrs[:disposition]]

    # leave remand reasons in tact if an issue is opted into AMA, or the opt-in is rolled back
    return if [disposition, new_disposition].include? "AMA SOC/SSOC Opt-in"

    if disposition.eql?("Remanded") && !new_disposition.eql?("Remanded")
      delete_remand_reasons!(*args)
      return
    end

    fail_if_no_remand_reasons!(new_disposition, issue_attrs[:remand_reasons])

    remand_reasons = RemandReasonMapper.convert_to_vacols_format(
      issue_attrs[:vacols_user_id],
      issue_attrs[:remand_reasons]
    )
    args.push(remand_reasons)

    if disposition.eql?("Remanded")
      update_remand_reasons!(*args)
    elsif new_disposition.eql?("Remanded")
      create_remand_reasons!(*args)
    end
  end

  def self.fail_if_no_remand_reasons!(new_disposition, remand_reasons)
    if new_disposition == "Remanded" && remand_reasons.blank?
      msg = "Remand reasons must be present when issue disposition is remanded"
      fail Caseflow::Error::RemandReasonRepositoryError, msg
    end
  end
end
