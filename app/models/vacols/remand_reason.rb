class VACOLS::RemandReason < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rmdrea"

  CODES = Constants::ACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys).concat(
    Constants::INACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys)
  ).freeze

  validates :rmdkey, :rmdissseq, :rmdval, :rmddev, :rmdmdusr, :rmdmdtim, presence: true, on: :create
  validates :rmdval, inclusion: { in: CODES }

  def self.create_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    (remand_reasons || []).each { |remand_reason| create!(remand_reason.merge(rmdkey: rmdkey, rmdissseq: rmdissseq)) }
  end

  def self.load_remand_reasons(rmdkey, rmdissseq)
    VACOLS::RemandReason.where(rmdkey: rmdkey, rmdissseq: rmdissseq)
  end

  def self.delete_remand_reasons!(rmdkey, rmdissseq)
    load_remand_reasons(rmdkey, rmdissseq).delete_all
  end

  def self.update_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    load_remand_reasons(rmdkey, rmdissseq).map.with_index do |_reason, idx|
      updated_reason = remand_reasons[idx]
      update(updated_reason)
    end
  end
  # :nocov:
end
