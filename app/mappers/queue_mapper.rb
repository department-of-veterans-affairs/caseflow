module QueueMapper
  WORK_PRODUCTS = {
    DEC: "Decision",
    IME: "OMO - IME",
    VHA: "OMO - VHA"
  }.freeze

  OVERTIME_WORK_PRODUCTS = {
    OTD: "Decision",
    OTI: "OMO - IME",
    OTV: "OMO - VHA"
  }.freeze

  def self.case_decision_fields_to_vacols_codes(info)
    {
      note: info[:note],
      document_id: info[:document_id],
      work_product: work_product_to_vacols_format(info[:work_product], info[:overtime])
    }.select { |k, _v| info.keys.map(&:to_sym).include? k } # only send updates to key/values that are passed
  end

  def self.work_product_to_vacols_format(work_product, overtime)
    overtime ? OVERTIME_WORK_PRODUCTS.key(work_product) : WORK_PRODUCTS.key(work_product)
  end
end
