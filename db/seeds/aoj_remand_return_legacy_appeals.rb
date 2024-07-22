# frozen_string_literal: true

module Seeds
  class AojRemandReturnLegacyAppeals < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initialize_ssn
    end

    def seed!
      # call new seed methods here
    end

    private

    def initialize_ssn
      @ssn ||= 210_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @ssn + 1))
        @ssn += 1000
      end
    end

    def create_correspondent(options = {})
      @ssn += 1 unless options[:ssn]

      params = {
        stafkey: @ssn,
        ssn: @ssn,
        susrtyp: "VETERAN",
        ssalut: nil,
        snamef: Faker::Name.first_name,
        snamemi: Faker::Name.initials(number: 1),
        snamel: Faker::Name.last_name,
        saddrst1: Faker::Address.street_name,
        saddrcty: Faker::Address.city,
        saddrstt: Faker::Address.state_abbr,
        saddrzip: Faker::Address.zip,
        staduser: "FAKEUSER",
        stadtime: 10.years.ago.to_datetime,
        sdob: 50.years.ago,
        sgender: Faker::Gender.short_binary_type
      }

      correspondent = VACOLS::Correspondent.find_by(ssn: options[:ssn] || @ssn) || create(:correspondent, params.merge(options))

      unless Veteran.find_by(ssn: @ssn)
        create(
          :veteran,
          first_name: correspondent.snamef,
          last_name: correspondent.snamel,
          name_suffix: correspondent.ssalut,
          ssn: correspondent.ssn,
          participant_id: correspondent.ssn,
          file_number: correspondent.ssn
        )
      end

      correspondent
    end

    # add new seed methods below
  end
end
