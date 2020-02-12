# frozen_string_literal: true

class ETL::OrganizationSyncer < ETL::Syncer
  def origin_class
    ::Organization
  end

  def target_class
    ETL::Organization
  end
end
