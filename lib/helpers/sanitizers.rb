require "faker"

class Helpers::Sanitizers
  def self.random_or_nil(value)
    return value if ::Faker::Number.number(1).to_i < 5
    nil
  end

  def self.sanitize_staff(staff)
    ::Faker::Config.random = Random.new(Digest::MD5.hexdigest(staff.slogid).to_i(16))

    staff.assign_attributes(
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
      sspare1: nil,
      sspare2: nil,
      sspare3: nil,
      sdomainid: "FAKELOGIN" + staff.slogid
    )
  end

  def self.sanitize_travel_board(travel_board)
    ::Faker::Config.random = Random.new((travel_board.tbyear + travel_board.tbtrip.to_s).to_i)

    travel_board.assign_attributes(
      tbbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
      tbropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
    )
  end

  def self.sanitize_case(vacols_case)
    ::Faker::Config.random = Random.new(vacols_case.bfkey.to_i)

    vacols_case.assign_attributes(
      bfcorlid: ::Faker::Number.number(9) + "S",
      bfcaseva: nil,
      bfcasevb: nil,
      bfcasevc: nil,
      bfic: nil,
      bfio: nil
    )

    vacols_case.correspondent.assign_attributes(
      ssn: random_or_nil(::Faker::Number.number(9)),
      snamef: ::Faker::Name.first_name,
      snamemi: ::Faker::Name.initials(1),
      snamel: ::Faker::Name.last_name,
      stitle: ::Faker::Name.prefix,
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
      sspare1: vacols_case.correspondent.sspare1 ? ::Faker::Name.last_name : nil,
      sspare2: vacols_case.correspondent.sspare2 ? ::Faker::Name.first_name : nil,
      sspare3: vacols_case.correspondent.sspare3 ? ::Faker::Name.initials(1) : nil,
      sspare4: vacols_case.correspondent.sspare4 ? ::Faker::Name.suffix : nil,
      sfnod: vacols_case.correspondent.sfnod ? ::Faker::Date.between(Date.new(1980), Date.new(2018)) : nil,
      sdob: random_or_nil(::Faker::Date.between(Date.new(1960), Date.new(1990))),
      sgender: (::Faker::Number.number(1).to_i < 5) ? "M" : "F",
      susrpw: nil,
      susrsec: nil,
      stc1: nil,
      stc2: nil,
      stc3: nil,
      stc4: nil,
      ssys: nil
    )

    representative = vacols_case.representative
    if representative
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
      )
    end

    folder = vacols_case.folder
    if folder
      folder.assign_attributes(
        titrnum: ::Faker::Number.number(9) + "S",
        tinum: ::Faker::Number.number(7),
        ticukey: nil,
        tidsnt: nil,
        tiaddrto: nil,
        tispare3: nil,
        tiread2: nil,
        tiwpptr: random_or_nil(::Faker::Lorem.sentence),
        tiwpptrt: nil,
        ticlstme: nil,
        tiactive: nil,
        tiread1: nil,
        timt: nil,
        tisys: nil
      )
    end

    vacols_case.notes.map do |note|
      note.assign_attributes(
        tskrqact: ::Faker::Lorem.sentence,
        tskrspn: random_or_nil(::Faker::Lorem.sentence),
        tsspare2: nil,
        tsspare3: nil,
        tsread1: nil,
        tsread: nil,
        tskorder: nil,
        tssys: nil
      )
    end

    vacols_case.case_issues.map do |note|
      note.assign_attributes(
        issdesc: ::Faker::Lorem.sentence # do better Mark
      )
    end

    vacols_case.case_hearings.map do |hearing|
      hearing.assign_attributes(
        repname: ::Faker::Name.name,
        notes1: random_or_nil(::Faker::Lorem.sentence),
        vdbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
        vdropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
      )
    end

    vacols_case.decass.map do |decass|
      decass.assign_attributes(
        debmcom: decass.debmcom ? ::Faker::Lorem.sentence : nil,
        deatcom: decass.deatcom ? ::Faker::Lorem.sentence : nil,
        dehours: decass.dehours ? ::Faker::Number.number(15) : nil
      )
    end
  end
end
