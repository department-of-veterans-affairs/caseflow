# frozen_string_literal: true

class ETL::OrganizationsUserSyncer < ETL::Syncer
  def origin_class
    ::OrganizationsUser
  end

  def target_class
    ETL::OrganizationsUser
  end
end
