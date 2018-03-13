class VACOLS::Decass < VACOLS::Record
  self.table_name = "vacols.decass"
  self.primary_key = "defolder"

  has_one :case, foreign_key: :bfkey

  # :nocov:
  def update_decass_record!(decision_info)
    # TODO: validate here presence here
    MetricsService.record("VACOLS: update_decass_record! #{defolder}",
                          service: :vacols,
                          name: "update_decass_record") do
      update(decision_info)
    end
  end
  # :nocov:
end
