# frozen_string_literal: true

require "faker"

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/PerceivedComplexity

# In order to add a new table to this sanitization list, you'll need to add two methods.
# If the new table's class name is VACOLS::KlassName, you'll need a method called white_list_klassname
# that returns a string array with all of the attributes in that class to allow into our local data.
# You'll also need a method called sanitize_klassname which assigns_attributes to any fields you want
# to fake out. The first line of this method should use a key from the table to seed the Faker randomization
# so that our randomizations are deterministic for a given row.
class Sanitizers
  def errors
    @errors ||= []
  end

  def staff_id_hash
    @staff_id_hash ||= {}
  end

  # Utility method to randomly either write a value, or nil
  def random_or_nil(value)
    return value if ::Faker::Number.number(digits: 1).to_i < 5

    nil
  end

  VETID_REGEX = /((?:^|[^0-9]|SS\ )[0-9]{3}[-\ ]?[0-9]{2}[-\ ]?[0-9]{4}(?![0-9])S?|(?:^|[^0-9]|C )
    [0-9]{1,2}\ ?[0-9]{3}\ ?[0-9]{3}(?![0-9])C?)/x.freeze
  EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i.freeze
  PHONE_REGEX = /\(?([0-9]{3})\)?[-.●]?([0-9]{3})[-.●]?([0-9]{4})/.freeze
  SENTENCE_REGEX = /[^\s]\s[^\s]/.freeze

  # Anything in this array will not throw PII warnings even if it looks like PII.
  # Note Staff-snamel is only used when it's associated with a numerical location or RO, in
  # those situations it's a description of the location, not an actual last name.
  def ignore_pii_in_fields
    %w[VACOLS::Issref-prog_desc VACOLS::Issref-iss_desc VACOLS::Issref-lev1_desc VACOLS::Issref-lev2_desc
       VACOLS::Issref-lev3_desc
       VACOLS::Vftypes-ftdesc VACOLS::Vftypes-ftsys
       VACOLS::Case-bfkey VACOLS::Case-bfcorkey
       VACOLS::Folder-ticknum VACOLS::Folder-ticorkey
       VACOLS::Representative-repkey VACOLS::Representative-repcorkey
       VACOLS::Correspondent-stafkey
       VACOLS::CaseIssue-isskey
       VACOLS::Note-tasknum VACOLS::Note-tsktknm VACOLS::Note-tskstfas
       VACOLS::Decass-defolder
       VACOLS::CaseHearing-folder_nr
       VACOLS::Staff-stitle VACOLS::Staff-sorg
       VACOLS::Staff-snamel
       VACOLS::Actcode-actcdesc
       VACOLS::Decass-dedocid]
  end

  def look_for_pii(record)
    record.attributes.each do |k, v|
      next if !v.is_a?(String) || ignore_pii_in_fields.include?("#{record.class.name}-#{k}")

      errors.push("WARNING -- Probable vetid: #{record.class.name}-#{k}-#{v}") if VETID_REGEX.match?(v)
      errors.push("WARNING -- Probable email: #{record.class.name}-#{k}-#{v}") if EMAIL_REGEX.match?(v)
      errors.push("WARNING -- Probable phone number: #{record.class.name}-#{k}-#{v}") if PHONE_REGEX.match?(v)
      errors.push("WARNING -- Possible PII in freetext: #{record.class.name}-#{k}-#{v}") if SENTENCE_REGEX.match?(v)
    end
  end

  # Utility method to nil out values that are not white listed
  def white_list(record, array_of_fields)
    hash_to_nil_fields = (record.attribute_names - array_of_fields).reduce({}) do |acc, field|
      acc[field] = nil
      acc
    end

    record.assign_attributes(hash_to_nil_fields)
  end

  def switch_slogid(record)
    record.attributes.each do |k, v|
      next if !staff_id_hash[v] || RO_REGEX =~ v || LOCATION_REGEX =~ v || CO_LOCATED_TEAM_REGEX =~ v

      record[k] = staff_id_hash[v][:login]
    end
  end

  # Entry method that calls the given klass' white_list and sanitize methods
  def sanitize(klass, record)
    table_name = klass.name.split("::")[1].downcase

    exist_hash = record.attributes.transform_values do |v|
      !v.nil?
    end

    white_list(record, send("white_list_#{table_name}"))
    look_for_pii(record)
    send("sanitize_#{table_name}", record, exist_hash)
    switch_slogid(record)
  end

  # Staff table
  def white_list_staff
    %w[stafkey susrtyp ssalut stitle snamel sorg slogid sdept staduser stadtime
       stmduser stmdtime stc1 stc2 stc3 stc4 sactive smemgrp sattyid svlj]
  end

  RO_REGEX = /^RO\d\d?$/.freeze
  LOCATION_REGEX = /^\d+$/.freeze
  CO_LOCATED_TEAM_REGEX = /^A1|A2$/.freeze

  def generate_staff_mapping(staff, record_index)
    if RO_REGEX.match(staff.stafkey) || LOCATION_REGEX.match(staff.stafkey)
      staff_id_hash[staff.stafkey] = {
        login: staff.slogid,
        stafkey: staff.stafkey,
        first_name: nil,
        middle_initial: nil,
        last_name: staff.snamel
      }
    else
      ::Faker::Config.random = Random.new(record_index)

      first_name = ::Faker::Name.first_name
      last_name = ::Faker::Name.last_name
      login = (first_name[0..0] + last_name[0..7]).upcase

      count = staff_id_hash.values.count { |row_hash| row_hash[:login].start_with?(login) }

      login = "#{login}#{count}" if count > 0

      staff_id_hash[staff.stafkey] = {
        login: login,
        stafkey: login,
        first_name: first_name,
        middle_initial: ::Faker::Name.initials(number: 1),
        last_name: last_name
      }
    end
  end

  def sanitize_staff(staff, exist_hash)
    row_hash = staff_id_hash[staff.stafkey]
    staff.assign_attributes(
      snamef: row_hash[:first_name],
      snamemi: row_hash[:middle_initial],
      snamel: row_hash[:last_name],
      slogid: row_hash[:login],
      stafkey: row_hash[:login],
      saddrst1: exist_hash["saddrst1"] ? ::Faker::Address.street_address : nil,
      saddrst2: exist_hash["saddrst2"] ? ::Faker::Address.secondary_address : nil,
      saddrcty: exist_hash["saddrcty"] ? ::Faker::Address.city : nil,
      saddrstt: exist_hash["saddrstt"] ? ::Faker::Address.state_abbr : nil,
      saddrcnty: exist_hash["saddrcnty"] ? ::Faker::Address.country_code_long : nil,
      saddrzip: exist_hash["saddrzip"] ? ::Faker::Address.zip_code : nil,
      stelw: exist_hash["stelw"] ? ::Faker::PhoneNumber.phone_number : nil,
      stelfax: exist_hash["stelfax"] ? ::Faker::PhoneNumber.phone_number : nil,
      stelwex: exist_hash["stelwex"] ? ::Faker::PhoneNumber.extension : nil,
      stelh: exist_hash["stelh"] ? ::Faker::PhoneNumber.phone_number : nil,
      snotes: exist_hash["snotes"] ? ::Faker::Lorem.sentence : nil,
      sdomainid: exist_hash["sdomainid"] ? "BVA#{row_hash[:login]}" : nil
    )
  end

  # Travel Board
  def white_list_travelboardschedule
    %w[tbyear tbtrip tbleg tbro tbstdate tbenddate tbmem1 tbmem2 tbmem3 tbmem4 tbaty1 tbaty2
       tbaty3 tbaty4 tbadduser tbaddtime tbmoduser tbmodtime tbcancel]
  end

  def sanitize_travelboardschedule(travel_board, _exist_hash)
    ::Faker::Config.random = Random.new((travel_board.tbyear + travel_board.tbtrip.to_s).to_i)

    travel_board.assign_attributes(
      tbbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
      tbropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
    )
  end

  # Issref
  def white_list_issref
    %w[prog_code prog_desc iss_code iss_desc lev1_code lev1_desc lev2_code lev2_desc lev3_code lev3_desc]
  end

  def sanitize_issref(issref, _exist_hash)
    # Nothing to sanitize in this table
  end

  # Vftypes
  def white_list_vftypes
    %w[ftkey ftdesc ftadusr ftadtim ftmdusr ftmdtim ftactive fttype ftsys ftspare1 ftspare2 ftspare3]
  end

  def sanitize_vftypes(vftypes, _exist_hash)
    # Nothing to sanitize in this table
  end

  # Actcode
  def white_list_actcode
    %w[actckey actcdesc actcsec actcukey actcdtc actadusr actadtim actmdusr actmdtim acactive actsys actdesc2
       acspare1 acspare2 acspare3]
  end

  def sanitize_actcode(actcode, _exist_hash)
    # Nothing to sanitize in this table
  end

  # Folder
  def white_list_folder
    %w[ticknum ticorkey tistkey tifiloc tidrecv tiddue
       tidcls tiaduser tiadtime timduser timdtime tiresp1 tikeywrd tisubj1 tisubj tisubj2
       tiagor tiasbt tigwui tihepc tiaids timgas tiptsd tiradb tiradn tisarc tisexh titoba tinosc
       ti38us tinnme tinwgr tipres titrtm tinoot tioctime tiocuser tidktime tidkuser tipulac
       ticerullo tivbms]
  end

  def sanitize_folder(folder, exist_hash)
    ::Faker::Config.random = Random.new(folder.ticknum.to_i)

    folder.assign_attributes(
      titrnum: ::Faker::Number.number(digits: 9) + "S",
      tinum: ::Faker::Number.number(digits: 7),
      tiwpptr: random_or_nil(::Faker::Lorem.sentence),
      tispare1: exist_hash["tispare1"] ? ::Faker::Name.last_name : nil,
      tispare2: exist_hash["tispare2"] ? ::Faker::Name.first_name : nil,
      tiread2: exist_hash["tiread2"] ? ::Faker::Number.number(digits: 7) : nil
    )
  end

  # Representative
  def white_list_representative
    %w[repkey repaddtime reptype repso repmoduser repmodtime repdirpay repdfee
       repfeerecv replastdoc repfeedisp repcorkey repacknw]
  end

  def sanitize_representative(representative, _exist_hash)
    ::Faker::Config.random = Random.new(representative.repkey.to_i)

    representative.assign_attributes(
      replast: ::Faker::Name.last_name,
      repfirst: ::Faker::Name.first_name,
      repmi: ::Faker::Name.initials(number: 1),
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

  # Vftypes
  def white_list_correspondent
    %w[stafkey susrtyp staduser stadtime stmduser stmdtime sactive]
  end

  def sanitize_correspondent(correspondent, exist_hash)
    ::Faker::Config.random = Random.new(Digest::SHA256.hexdigest(correspondent.stafkey).to_i(16))

    correspondent.assign_attributes(
      ssn: random_or_nil(::Faker::Number.number(digits: 9)),
      ssalut: ::Faker::Name.suffix,
      snamef: ::Faker::Name.first_name,
      snamemi: ::Faker::Name.initials(number: 1),
      snamel: ::Faker::Name.last_name,
      slogid: ::Faker::Number.number(digits: 9) + "S",
      stitle: ::Faker::Name.prefix,
      sorg: random_or_nil(::Faker::Lorem.sentence),
      sdept: random_or_nil(::Faker::Lorem.sentence),
      saddrst1: ::Faker::Address.street_address,
      saddrst2: random_or_nil(::Faker::Address.secondary_address),
      saddrcty: ::Faker::Address.city,
      saddrstt: ::Faker::Address.state_abbr,
      saddrcnty: ::Faker::Address.country_code_long,
      saddrzip: ::Faker::Address.zip_code,
      stelw: ::Faker::PhoneNumber.phone_number,
      stelfax: random_or_nil(::Faker::PhoneNumber.phone_number),
      stelwex: random_or_nil(::Faker::PhoneNumber.extension),
      stelh: random_or_nil(::Faker::PhoneNumber.phone_number),
      snotes: random_or_nil(::Faker::Lorem.sentence),
      sspare1: exist_hash["sspare1"] ? ::Faker::Name.last_name : nil,
      sspare2: exist_hash["sspare2"] ? ::Faker::Name.first_name : nil,
      sspare3: exist_hash["sspare3"] ? ::Faker::Name.initials(number: 1) : nil,
      sspare4: exist_hash["sspare4"] ? ::Faker::Name.suffix : nil,
      sfnod: exist_hash["sfnod"] ? ::Faker::Date.between(from: Date.new(1980), to: Date.new(2018)) : nil,
      sdob: random_or_nil(::Faker::Date.between(from: Date.new(1960), to: Date.new(1990))),
      sgender: (::Faker::Number.number(digits: 1).to_i < 5) ? "M" : "F"
    )
  end

  # Issue
  def white_list_caseissue
    %w[isskey issseq issprog isscode isslev1 isslev2 isslev3 issdc issdcls issadtime issaduser issmdtime
       issmduser isssel issgr issdev]
  end

  def sanitize_caseissue(issue, _exist_hash)
    ::Faker::Config.random = Random.new(issue.isskey.to_i)

    issue.assign_attributes(
      issdesc: ::Faker::Lorem.sentence # do better Mark
    )
  end

  # Note
  def white_list_note
    %w[tasknum tsktknm tskstfas tskactcd tskclass tskdassn tskdtc tskddue tskdcls
       tskstown tskstat tskadusr tskadtm tskmdusr tskmdtm tsactive]
  end

  def sanitize_note(note, _exist_hash)
    ::Faker::Config.random = Random.new(note.tsktknm.to_i)

    note.assign_attributes(
      tskrqact: ::Faker::Lorem.sentence,
      tskrspn: random_or_nil(::Faker::Lorem.sentence)
    )
  end

  # CaseHearing
  def white_list_casehearing
    %w[hearing_pkseq hearing_type folder_nr hearing_date hearing_disp board_member
       team room mduser mdtime reqdate clsdate recmed consent conret
       contapes tranreq transent wbtapes wbbackup wbsent recprob taskno adduser addtime
       aod holddays vdkey canceldate]
  end

  ONLY_NUMBER_REGEX = /^\d*$/.freeze

  def sanitize_casehearing(hearing, _exist_hash)
    ::Faker::Config.random = Random.new(hearing.hearing_pkseq)

    # Note we only keep board_members when they have number IDs, not RO letter IDs
    hearing.assign_attributes(
      board_member: ONLY_NUMBER_REGEX.match?(hearing.board_member) ? hearing.board_member : nil,
      repname: ::Faker::Name.name,
      rep_state: ::Faker::Address.state_abbr,
      notes1: random_or_nil(::Faker::Lorem.sentence),
      vdbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
      vdropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
    )
  end

  # Decass
  def white_list_decass
    %w[defolder deatty deteam depdiff defdiff deassign dereceive deprod detrem dearem deoq
       deadusr deadtim deprogrev demdusr demdtim delock dememid decomp dedeadline
       deicr defcr deqr1 deqr2 deqr3 deqr4 deqr5 deqr6 deqr7 deqr8 deqr9 deqr10 deqr11 derecommend dedocid]
  end

  def sanitize_decass(decass, exist_hash)
    ::Faker::Config.random = Random.new(decass.defolder.to_i)

    decass.assign_attributes(
      debmcom: exist_hash["debmcom"] ? ::Faker::Lorem.sentence : nil,
      deatcom: exist_hash["deatcom"] ? ::Faker::Lorem.sentence : nil,
      dehours: exist_hash["dehours"] ? ::Faker::Number.number(digits: 1).to_d : nil
    )
  end

  # Case
  def white_list_case
    %w[bfkey bfddec bfcorkey bfdcn bfdocind bfpdnum bfdpdcn bforgtic bfdorg bfdnod
       bfdsoc bfd19 bf41stat bfmstat bfmpro bfdmcon bfregoff bfissnr bfrdmref bfcasev
       bfboard bfbsasgn bfattid bfdasgn bfdqrsnt bfdlocin bfdloout
       bfstasgn bfcurloc bfnrcopy bfmemid bfdmem bfnrci bfcallup bfcallyymm bfhines bfdcfld1
       bfdcfld2 bfdcfld3 bfac bfdc bfha bfms bfoc bfsh bfso bfhr bfst bfdrodec bfssoc1
       bfssoc2 bfssoc3 bfssoc4 bfssoc5 bfdtb bftbind bfdcue bfdvin bfdvout bfddro bfddvwrk
       bfddvdsp bfddvret bfdrortr bfro1 bflot bfbox bfdtbready bfarc bfdarcin bfdarcout bfarcdisp
       bfsub bfdcertool]
  end

  def sanitize_case(vacols_case, _exist_hash)
    ::Faker::Config.random = Random.new(vacols_case.bfkey.to_i)

    vacols_case.assign_attributes(
      bfcorlid: ::Faker::Number.number(digits: 9) + "S",
      bfcclkid: ::Faker::Number.number(digits: 7)
    )
  end
end

# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
