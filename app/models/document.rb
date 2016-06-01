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

  attr_accessor :type, :received_at

  def self.from_vbms_document(vbms_document)
    new(
      type: TYPES[vbms_document.doc_type] || :other,
      received_at: vbms_document.received_at
    )
  end
end
