class AttorneyCaseReview < ActiveRecord::Base
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :attorney, :type, :task_id, :reviewing_judge, :document_id, :work_product, presence: true
  validates :overtime, inclusion: { in: [true, false] }

  # task ID is vacols_id concatenated with the date assigned
  validates :task_id, format: { with: /\A[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }

  EXCEPTIONS = [QueueRepository::ReassignCaseToJudgeError, VacolsHelper::MissingRequiredFieldError].freeze

  class << self
    attr_writer :repository

    def complete!(params)
      transaction do
        # Save to the Caseflow DB first to ensure required fields are present
        record = create(params)
        return unless record.valid?

        begin
          repository.reassign_case_to_judge(params)
        rescue *EXCEPTIONS
          raise ActiveRecord::Rollback
        end
        record
      end
    end

    def repository
      @repository ||= QueueRepository
    end
  end
end
