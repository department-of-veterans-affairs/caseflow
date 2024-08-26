# frozen_string_literal: true

class AppealAffinity < CaseflowRecord
  validates :case_id, :docket, presence: true
  validates :case_type, inclusion: %w[Appeal VACOLS::Case]
  validates :priority, inclusion: [true, false]

  belongs_to :distribution

  after_save :update_distribution_task_instructions, if: :should_update_task_instructions?

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

  def update_distribution_task_instructions
    distribution_task = DistributionTask.find_by(appeal: self.case, status: Constants.TASK_STATUSES.assigned)
    return unless distribution_task

    distribution_task.instructions << "Affinity start date: #{affinity_start_date.to_date.strftime('%m/%d/%Y')}"
    distribution_task.save!
  end

  def should_update_task_instructions?
    Constants::AMA_DOCKETS.include?(docket) && affinity_start_date?
  end
end
