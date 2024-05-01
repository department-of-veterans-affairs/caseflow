# frozen_string_literal: true

class AppealAffinity < CaseflowRecord
  validates :case_id, :docket, :affinity_start_date, presence: true
  validates :priority, inclusion: [true, false]

  belongs_to :distribution

  # A true polymorphic association isn't possible because of the differences in foreign keys between the various
  # tables, so instead we define a getter which will return the correct type of record based on case_type
  def case
    case case_type
    when Appeal.name
      Appeal.find_by(uuid: case_id) if case_type == Appeal.name
    when VACOLS::Case.name
      VACOLS::Case.find_by(bfkey: case_id) if case_type == VACOLS::Case.name
    end
  end
end
