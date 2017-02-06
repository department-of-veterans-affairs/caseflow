class VACOLS::Record < ActiveRecord::Base
  self.abstract_class = true

  establish_connection "#{Rails.env}_vacols".to_sym
  ActiveSupport.run_load_hooks(:active_record_vacols, VACOLS::Record)
end
