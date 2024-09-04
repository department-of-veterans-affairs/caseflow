# frozen_string_literal: true

require "rake"

module Seeds
  class MstPactLegacyCaseAppeals < Base

    USER_CSS_IDS = [
      'BVASRITCHIE',
      'BVASCASPER1',
      'BVAEBECKER',
      'BVAKKEELING'
    ]

    # :reek:UtilityFunction
    def seed!
      generate_legacy_appeals
    end

    # confirms the user CSS IDS are for valid users or skip
    # seeds come from seed_legacy_appeals.rake
    # :reek:UtilityFunction
    def generate_legacy_appeals
      USER_CSS_IDS.each do |id|
        next unless User.find_by_css_id(id)

        Rake::Task['db:generate_legacy_appeals'].invoke(true, id)
        Rake::Task['db:generate_legacy_appeals'].reenable
      end
    end

  end
end
