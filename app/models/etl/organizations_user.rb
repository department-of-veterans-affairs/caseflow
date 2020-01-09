# frozen_string_literal: true

# copy of OrganizationsUser model

class ETL::OrganizationsUser < ETL::Record
  class << self
    private

    # original records get deleted and re-created as users change orgs.
    # so we avoid using the PK autoincrementing "id" to sync and instead rely on the unique index cols.
    def find_by_primary_key(original)
      find_by(user_id: original.user_id, organization_id: original.organization_id)
    end
  end
end
