class Document
  include ActiveModel::Model

  VALID_TYPES = [:nod, :soc, :ssoc, :form9].freeze

  attr_accessor :type, :received_at
end
