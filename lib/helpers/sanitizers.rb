require "faker"

class Helpers::Sanitizers
  def self.random_or_nil(value)
    return value if ::Faker::Number.number(1).to_i < 5
    nil
  end

  def self.sanitize_case(vacols_case)
    ::Faker::Config.random = Random.new(vacols_case.bfkey.to_i)

    vacols_case.assign_attributes(
      bfcorlid: ::Faker::Number.number(9)
    )

    vacols_case.correspondent.assign_attributes(
      ssn: ::Faker::Number.number(9),
      snamef: ::Faker::Name.first_name,
      snamemi: ::Faker::Name.initials(1),
      snamel: ::Faker::Name.last_name,
      saddrnum: nil,
      saddrst1: ::Faker::Address.street_address,
      saddrst2: random_or_nil(::Faker::Address.secondary_address),
      saddrcty: ::Faker::Address.city,
      saddrstt: ::Faker::Address.state_abbr,
      saddrcnty: ::Faker::Address.country_code_long,
      saddrzip: ::Faker::Address.zip_code,
      stelw: ::Faker::PhoneNumber.phone_number,
      stelfax: random_or_nil(::Faker::PhoneNumber.phone_number),
      stelwex: random_or_nil(::Faker::PhoneNumber.phone_number),
      stelh: random_or_nil(::Faker::PhoneNumber.phone_number),
      snotes: random_or_nil(::Faker::Lorem.sentence),
      sorc1: nil,
      sorc2: nil,
      sorc3: nil,
      sorc4: nil,
      sspare1: ::Faker::Name.last_name,
      sspare2: ::Faker::Name.first_name,
      sspare3: ::Faker::Name.initials(1),
      sspare4: ::Faker::Name.suffix,
      sfnod: random_or_nil(::Faker::Date.between(Date.new(1980), Date.new(2018))),
      sdob: ::Faker::Date.between(Date.new(1960), Date.new(1990))
    )
    representative = vacols_case.representative
    representative.assign_attributes(
      replast: ::Faker::Name.last_name,
      repfirst: ::Faker::Name.first_name,
      repmi: ::Faker::Name.initials(1),
      repsuf: ::Faker::Name.suffix,
      repaddr1: ::Faker::Address.street_address,
      repaddr2: ::Faker::Address.secondary_address,
      repcity: ::Faker::Address.city,
      repst: ::Faker::Address.state_abbr,
      repzip: ::Faker::Address.zip_code,
      repphone: ::Faker::PhoneNumber.phone_number,
      repnotes: random_or_nil(::Faker::Lorem.sentence)
    ) if representative

    vacols_case.case_hearings.map do |hearing|
      hearing.assign_attributes(
        repname: ::Faker::Name.name,
        notes1: random_or_nil(::Faker::Lorem.sentence)
      )
    end
  end
end
