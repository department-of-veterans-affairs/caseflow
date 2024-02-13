# frozen_string_literal: true

module Seeds
  class PopulateCaseflowFromVacols
    def seed!
      populate_judges
      populate_attorneys
    end

    private

    # this will populate the redis cache and Caseflow DB with judges added to VACOLS using the .csv importer
    def populate_judges
      Judge.list_all
    end

    # this will populate the redis cache and Caseflow DB with attorneys added to VACOLS using the .csv importer
    def populate_attorneys
      Attorney.list_all
    end
  end
end
