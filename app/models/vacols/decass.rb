class VACOLS::Decass < VACOLS::Record
  self.table_name = "vacols.decass"
  self.primary_key = "defolder"

  has_one :case, foreign_key: :bfkey

  COLUMN_NAMES = {
    work_product: :deprod,
    note: :deatcom,
    document_id: :dedocid,
    reassigned_at: :dereceive
  }.freeze

  # :nocov:
  def update_decass_record!(decision_info)
    attrs = decision_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_decass_record! #{defolder}",
                          service: :vacols,
                          name: "update_decass_record") do
      update(attrs)
    end
  end
  # :nocov:
end
