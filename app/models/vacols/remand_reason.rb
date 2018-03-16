class VACOLS::RemandReason < VACOLS::Record
  self.table_name = "vacols.rmdrea"

  CODES = %w[AA AB AC BA BB BC BD BE BF BG BH BI CA CB CC
             CD CE CF CG CH DA DB DC DD DE DF DG DH DI EA
             EB EC ED EE EF EG EH EI EJ EK].freeze

  validates :rmdkey, :rmdissseq, :rmdval, :rmddev, :rmdmdusr, :rmdmdtim, presence: true, on: :create
  validates :rmdval, inclusion: { in: CODES }

  def self.create_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    return if remand_reasons.blank?
    remand_reasons.each { |remand_reason| create!(remand_reason.merge(rmdkey: rmdkey, rmdissseq: rmdissseq)) }
  end
end
