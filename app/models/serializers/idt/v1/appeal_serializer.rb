# frozen_string_literal: true

class Idt::V1::AppealSerializer < ActiveModel::Serializer
  def id
    object.is_a?(LegacyAppeal) ? object.vacols_id : object.uuid
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :file_number do
    object.is_a?(LegacyAppeal) ? object.sanitized_vbms_id : object.veteran_file_number
  end
  attribute :docket_number
  attribute :docket_name
  attribute :number_of_issues

  attribute :days_waiting do
    @instance_options[:task] ? @instance_options[:task].days_waiting : nil
  end

  attribute :assigned_by do
    object.reviewing_judge_name
  end

  attribute :documents do
    object.attorney_case_reviews.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
  end
end
