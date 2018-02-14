class AttorneyCaseReview < ActiveRecord::Base
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"

  validates :attorney, :reviewing_judge, :document_id, :work_product, :overtime, presence: true

  class << self
    attr_writer :repository

    def complete!(params)
      transaction do
        # Save to the Caseflow DB first to ensure required fields are present
        vacols_id = params.delete(:vacols_id)
        record = create(params)

        return unless record.valid?

        begin
          repository.reassign_case_to_judge(
            vacols_id: vacols_id,
            attorney_css_id: record.attorney.css_id,
            judge_css_id: record.reviewing_judge.css_id,
            work_product: record.work_product,
            document_id: record.document_id,
            overtime: record.overtime,
            note: record.note
            )
        rescue ErrorReassigningCaseToJudge
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
