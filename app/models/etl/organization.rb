# frozen_string_literal: true

# copy of Organization model

class ETL::Organization < ETL::Record
  self.inheritance_column = :_type_disabled # no STI on ETL
end
