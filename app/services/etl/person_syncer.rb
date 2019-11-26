# frozen_string_literal: true

class ETL::PersonSyncer < ETL::Syncer
  def origin_class
    ::Person
  end

  def target_class
    ETL::Person
  end
end
