# frozen_string_literal: true

class DistributedCase < CaseflowRecord
  belongs_to :distribution
  belongs_to :task

  validates :case_id, :distribution, :docket, :ready_at, presence: true
  validates :genpop, inclusion: [true, false], if: :docket_has_hearing_option
  validates :genpop_query, presence: true, if: :docket_has_hearing_option
  validates :task_id, presence: true, if: :ama_docket
  validates :docket_index, presence: true, if: :legacy_nonpriority
  validates :priority, inclusion: [true, false]

  def rename_for_redistribution!
    ymd = Time.zone.today.strftime("%F")
    update!(case_id: "#{case_id}-redistributed-#{ymd}")
  end

  def flag_redistribution(task)
    Rails.logger.error("A distributed case, id #{id}, "\
      "\n already exists for appeal of uuid #{task.appeal.uuid}.")
    Raven.capture_message("A distributed case, id #{id}, "\
        "\n already exists for appeal of uuid #{task.appeal.uuid}.")
  end

  private

  def docket_has_hearing_option
    %w[legacy hearing].include?(docket)
  end

  def ama_docket
    %w[direct_review evidence_submission hearing].include?(docket)
  end

  def legacy_nonpriority
    docket == "legacy" && !priority
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: distributed_cases
#
#  id              :bigint           not null, primary key
#  docket          :string
#  docket_index    :integer
#  genpop          :boolean
#  genpop_query    :string
#  priority        :boolean
#  ready_at        :datetime
#  created_at      :datetime
#  updated_at      :datetime         indexed
#  case_id         :string           indexed
#  distribution_id :integer
#  task_id         :integer
#
# Foreign Keys
#
#  fk_rails_b31c8376f7  (task_id => tasks.id)
#  fk_rails_bfca65a760  (distribution_id => distributions.id)
#
