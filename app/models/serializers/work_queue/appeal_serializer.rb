class WorkQueue::AppealSerializer < ActiveModel::Serializer

  has_many :hearings, serializer: ::WorkQueue::HearingSerializer
  has_many :issues, serializer: ::WorkQueue::IssueSerializer

  attribute :veteran_full_name
  attribute :vbms_id
  attribute :vacols_id
  attribute :type
  attribute :aod
  attribute :regional_office
  attribute :issues
end
