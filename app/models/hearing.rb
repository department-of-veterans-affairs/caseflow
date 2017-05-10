class Hearing
  include ActiveModel::Model

  attr_accessor :date, :type, :regional_office_key, :judge_vacols_id, :vacols_case_id

  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(vacols_case_id)
  end
end
