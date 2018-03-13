module QueueMapper
  COLUMN_NAMES = {
    work_product: :deprod,
    note: :deatcom,
    document_id: :dedocid
  }.freeze

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

  def self.rename_and_validate_decass_attrs(decass_attrs)
    response = COLUMN_NAMES.keys.each_with_object({}) do |k, result|
      # skip only if the key is not passed, if the key is passed and the value is nil - include that
      next unless decass_attrs.keys.include? k

      if k == :work_product
        decass_attrs[k] = work_product_to_vacols_code(decass_attrs[:work_product], decass_attrs[:overtime])
      end

      result[COLUMN_NAMES[k]] = decass_attrs[k]
      result
    end
    VacolsHelper.validate_presence(response, [:deprod, :dedocid])
    response.merge(dereceive: VacolsHelper.local_date_with_utc_timezone)
  end

  def self.work_product_to_vacols_code(work_product, overtime)
    overtime ? OVERTIME_WORK_PRODUCTS.key(work_product) : WORK_PRODUCTS.key(work_product)
  end
end
