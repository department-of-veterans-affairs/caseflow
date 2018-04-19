class VACOLS::RemandReason < VACOLS::Record
  self.table_name = "vacols.rmdrea"

  CODES = Constants::ACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys).concat(
    Constants::INACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys)
  ).freeze

  validates :rmdkey, :rmdissseq, :rmdval, :rmddev, :rmdmdusr, :rmdmdtim, presence: true, on: :create
  validates :rmdval, inclusion: { in: CODES }

  def self.create_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    (remand_reasons || []).each { |remand_reason| create!(remand_reason.merge(rmdkey: rmdkey, rmdissseq: rmdissseq)) }
  end
end
