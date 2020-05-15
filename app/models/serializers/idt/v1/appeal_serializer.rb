# frozen_string_literal: true

class Idt::V1::AppealSerializer
  include FastJsonapi::ObjectSerializer
  set_id do |object|
    object.is_a?(LegacyAppeal) ? object.vacols_id : object.uuid
  end

  attribute :type do |object|
    object.class.name
  end
  attribute :veteran_first_name
  attribute :veteran_middle_name, &:veteran_middle_initial
  attribute :veteran_last_name
  attribute :file_number do |object|
    object.is_a?(LegacyAppeal) ? object.sanitized_vbms_id : object.veteran_file_number
  end
  attribute :docket_number
  attribute :docket_name
  attribute :number_of_issues

  attribute :days_waiting do |_object, params|
    params[:task] ? params[:task].days_waiting : nil
  end

  attribute :assigned_by, &:reviewing_judge_name

  attribute :documents do |object|
    object.attorney_case_reviews.sort_by(&:updated_at).reverse.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
  end
end
