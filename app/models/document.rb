class Document
  include ActiveModel::Model

  TYPES = {
    "73" => :nod,
    "95" => :soc,
    "97" => :ssoc,
    "179" => :form9,
    "713" => :nod,
    "856" => :nod,
    "857" => :form9
  }.freeze

  ALT_TYPES = {
    "Appeals - Notice of Disagreement (NOD)" => :nod,
    "Appeals - Statement of the Case (SOC)" => :soc,
    "Appeals - Substantive Appeal to Board of Veterans' Appeals" => :form9,
    "Appeals - Supplemental Statement of the Case (SSOC)" => :ssoc
  }.freeze

  attr_accessor :type, :alt_types, :vbms_doc_type, :received_at

  def type?(type)
    (self.type == type) || (alt_types || []).include?(type)
  end

  def self.from_vbms_document(vbms_document)
    new(
      type: TYPES[vbms_document.doc_type] || :other,
      alt_types: (vbms_document.alt_doc_types || []).map { |type| ALT_TYPES[type] },
      vbms_doc_type: vbms_document.doc_type,
      received_at: vbms_document.received_at
    )
  end
end
