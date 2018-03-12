require "faker"

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize

# In order to add a new table to this sanitization list, you'll need to add two methods.
# If the new table's class name is VACOLS::KlassName, you'll need a method called white_list_klassname
# that returns a string array with all of the attributes in that class to allow into our local data.
# You'll also need a method called sanitize_klassname which assigns_attributes to any fields you want
# to fake out. The first line of this method should use a key from the table to seed the Faker randomization
# so that our randomizations are deterministic for a given row.
class Helpers::Sanitizers
  def self.errors
    @errors ||= []
  end

  def self.staff_id_hash
    @staff_id_hash ||= {}
  end

  # Utility method to randomly either write a value, or nil
  def self.random_or_nil(value)
    return value if ::Faker::Number.number(1).to_i < 5
    nil
  end

  VETID_REGEX = /((?:^|[^0-9]|SS\ )[0-9]{3}[-\ ]?[0-9]{2}[-\ ]?[0-9]{4}(?![0-9])S?|(?:^|[^0-9]|C )
    [0-9]{1,2}\ ?[0-9]{3}\ ?[0-9]{3}(?![0-9])C?)/x
  EMAIL_REGEX = /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  PHONE_REGEX = /^\(?([0-9]{3})\)?[-.●]?([0-9]{3})[-.●]?([0-9]{4})$/
  SENTENCE_REGEX = /[^\s]\s[^\s]/

  def self.ignore_pii_in_fields
    %w[VACOLS::Issref-prog_code VACOLS::Issref-prog_desc VACOLS::Issref-iss_code VACOLS::Issref-iss_desc
       VACOLS::Issref-lev1_code VACOLS::Issref-lev1_desc VACOLS::Issref-lev2_code VACOLS::Issref-lev2_desc
       VACOLS::Issref-lev3_code VACOLS::Issref-lev3_desc
       VACOLS::Vftypes-ftkey VACOLS::Vftypes-ftdesc VACOLS::Vftypes-ftadusr VACOLS::Vftypes-ftadtim
       VACOLS::Vftypes-ftmdusr VACOLS::Vftypes-ftmdtim VACOLS::Vftypes-ftactive VACOLS::Vftypes-fttype
       VACOLS::Vftypes-ftsys VACOLS::Vftypes-ftspare1 VACOLS::Vftypes-ftspare2 VACOLS::Vftypes-ftspare3
       VACOLS::Case-bfkey VACOLS::Case-bfcorkey
       VACOLS::Folder-ticknum VACOLS::Folder-ticorkey
       VACOLS::Representative-repkey VACOLS::Representative-repcorkey
       VACOLS::Correspondent-stafkey
       VACOLS::CaseIssue-isskey
       VACOLS::Note-tasknum VACOLS::Note-tsktknm
       VACOLS::Decass-defolder
       VACOLS::CaseHearing-folder_nr
       VACOLS::Decass-dedocid
       VACOLS::Staff-stitle VACOLS::Staff-sorg]
  end

  def self.look_for_pii(record)
    record.attributes.each do |k, v|
      next if !v.kind_of?(String) || ignore_pii_in_fields.include?("#{record.class.name}-#{k}")

      errors.push("WARNING -- Probable vetid: #{record.class.name}-#{k}-#{v}") if VETID_REGEX.match(v)
      errors.push("WARNING -- Probable email: #{record.class.name}-#{k}-#{v}") if EMAIL_REGEX.match(v)
      errors.push("WARNING -- Probable phone number: #{record.class.name}-#{k}-#{v}") if PHONE_REGEX.match(v)
      errors.push("WARNING -- Possible PII in freetext: #{record.class.name}-#{k}-#{v}") if SENTENCE_REGEX.match(v)
    end
  end

  # Utility method to nil out values that are not white listed
  def self.white_list(record, array_of_fields)
    hash_to_nil_fields = (record.attribute_names - array_of_fields).reduce({}) do |acc, field|
      acc[field] = nil
      acc
    end

    record.assign_attributes(hash_to_nil_fields)
  end

  def self.switch_slogid(record)
    record.attributes.each do |k, v|
      record[k] = staff_id_hash[v] if staff_id_hash[v]
    end
  end

  # Entry method that calls the given klass' white_list and sanitize methods
  def self.sanitize(klass, record, record_index)
    table_name = klass.name.split("::")[1].downcase

    exist_hash = record.attributes.map { |k, v| [k, v.nil?] }.to_h

    white_list(record, send("white_list_#{table_name}"))
    look_for_pii(record)
    switch_slogid(record)
    send("sanitize_#{table_name}", record, exist_hash, record_index)
  end

  # Staff table
  def self.white_list_staff
    %w[stafkey susrtyp ssalut stitle sorg slogid sdept staduser stadtime
       stmduser stmdtime stc1 stc2 stc3 stc4 sactive smemgrp sattyid svlj]
  end

  def self.sanitize_staff(staff, _exist_hash, record_index)
    ::Faker::Config.random = Random.new(record_index)

    first_name = ::Faker::Name.first_name
    last_name = ::Faker::Name.last_name
    login = (first_name[0..0] + last_name[0..7]).upcase

    count = staff_id_hash.values.count(login)

    login = "#{login}#{count}" if count > 0

    staff_id_hash[staff.slogid] = login

    staff.assign_attributes(
      snamef: first_name,
      snamemi: ::Faker::Name.initials(1),
      snamel: last_name,
      slogid: login,
      stafkey: login,
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
      sdomainid: "BVA#{login}"
    )
  end

  # Travel Board
  def self.white_list_travelboardschedule
    %w[tbyear tbtrip tbleg tbro tbstdate tbenddate tbmem1 tbmem2 tbmem3 tbmem4 tbaty1 tbaty2
       tbaty3 tbaty4 tbadduser tbaddtime tbmoduser tbmodtime tbcancel]
  end

  def self.sanitize_travelboardschedule(travel_board, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new((travel_board.tbyear + travel_board.tbtrip.to_s).to_i)

    travel_board.assign_attributes(
      tbbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
      tbropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
    )
  end

  # Issref
  def self.white_list_issref
    %w[prog_code prog_desc iss_code iss_desc lev1_code lev1_desc lev2_code lev2_desc lev3_code lev3_desc]
  end

  def self.sanitize_issref(issref, _exist_hash, _record_index)
    # Nothing to sanitize in this table
  end

  # Vftypes
  def self.white_list_vftypes
    %w[ftkey ftdesc ftadusr ftadtim ftmdusr ftmdtim ftactive fttype ftsys ftspare1 ftspare2 ftspare3]
  end

  def self.sanitize_vftypes(vftypes, _exist_hash, _record_index)
    # Nothing to sanitize in this table
  end

  # Folder
  def self.white_list_folder
    %w[ticknum ticorkey tistkey tifiloc tidrecv tiddue
       tidcls tiaduser tiadtime timduser timdtime tiresp1 tikeywrd tisubj1 tisubj tisubj2
       tiagor tiasbt tigwui tihepc tiaids timgas tiptsd tiradb tiradn tisarc tisexh titoba tinosc
       ti38us tinnme tinwgr tipres titrtm tinoot tioctime tiocuser tidktime tidkuser tipulac
       ticerullo tivbms]
  end

  def self.sanitize_folder(folder, exist_hash, _record_index)
    ::Faker::Config.random = Random.new(folder.ticknum.to_i)

    folder.assign_attributes(
      titrnum: ::Faker::Number.number(9) + "S",
      tinum: ::Faker::Number.number(7),
      tiwpptr: random_or_nil(::Faker::Lorem.sentence),
      tispare1: exist_hash["tispare1"] ? ::Faker::Name.last_name : nil,
      tispare2: exist_hash["tispare2"] ? ::Faker::Name.first_name : nil,
      tiread2: exist_hash["tiread2"] ? ::Faker::Number.number(7) : nil
    )
  end

  # Representative
  def self.white_list_representative
    %w[repkey repaddtime reptype repsoå repmoduser repmodtime repdirpay repdfee
       repfeerecv replastdoc repfeedisp repcorkey repacknw]
  end

  def self.sanitize_representative(representative, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new(representative.repkey.to_i)

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

  # Vftypes
  def self.white_list_correspondent
    %w[stafkey susrtyp staduser stadtime stmduser stmdtime sactive]
  end

  def self.sanitize_correspondent(correspondent, exist_hash, _record_index)
    ::Faker::Config.random = Random.new(Digest::SHA256.hexdigest(correspondent.stafkey).to_i(16))

    correspondent.assign_attributes(
      ssn: random_or_nil(::Faker::Number.number(9)),
      ssalut: ::Faker::Name.suffix,
      snamef: ::Faker::Name.first_name,
      snamemi: ::Faker::Name.initials(1),
      snamel: ::Faker::Name.last_name,
      slogid: ::Faker::Number.number(9) + "S",
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
      sspare3: exist_hash["sspare3"] ? ::Faker::Name.initials(1) : nil,
      sspare4: exist_hash["sspare4"] ? ::Faker::Name.suffix : nil,
      sfnod: exist_hash["sfnod"] ? ::Faker::Date.between(Date.new(1980), Date.new(2018)) : nil,
      sdob: random_or_nil(::Faker::Date.between(Date.new(1960), Date.new(1990))),
      sgender: (::Faker::Number.number(1).to_i < 5) ? "M" : "F"
    )
  end

  # Issue
  def self.white_list_caseissue
    %w[isskey issseq issprog isscode isslev1 isslev2 isslev3 issdc issdcls issadtime issaduser issmdtime
       issmduser isssel issgr issdev]
  end

  def self.sanitize_caseissue(issue, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new(issue.isskey.to_i)

    issue.assign_attributes(
      issdesc: ::Faker::Lorem.sentence # do better Mark
    )
  end

  # Note
  def self.white_list_note
    %w[tasknum tsktknm tskstfas tskactcd tskclass tskdassn tskdtc tskddue tskdcls
       tskstown tskstat tskadusr tskadtm tskmdusr tskmdtm tsactive]
  end

  def self.sanitize_note(note, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new(note.tsktknm.to_i)

    note.assign_attributes(
      tskrqact: ::Faker::Lorem.sentence,
      tskrspn: random_or_nil(::Faker::Lorem.sentence)
    )
  end

  # CaseHearing
  def self.white_list_casehearing
    %w[hearing_pkseq hearing_type folder_nr hearing_date hearing_disp board_member
       team room mduser mdtime reqdate clsdate recmed consent conret
       contapes tranreq transent wbtapes wbbackup wbsent recprob taskno adduser addtime
       aod holdays vdkey canceldate]
  end

  def self.sanitize_casehearing(hearing, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new(hearing.hearing_pkseq)

    hearing.assign_attributes(
      repname: ::Faker::Name.name,
      rep_state: ::Faker::Address.state_abbr,
      notes1: random_or_nil(::Faker::Lorem.sentence),
      vdbvapoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number,
      vdropoc: ::Faker::Name.name + " " + ::Faker::PhoneNumber.phone_number
    )
  end

  # Decass
  def self.white_list_decass
    %w[defolder deatty deteam depdiff defdiff deassign dereceive deprod detrem dearem deoq
       deadusr deadtim deprogrev demdusr demdtim delock dememid decomp dedeadline
       deicr defcr deqr1 deqr2 deqr3 deqr4 deqr5 deqr6 deqr7 deqr8 deqr9 deqr10 deqr11 dedocid derecommend]
  end

  def self.sanitize_decass(decass, exist_hash, _record_index)
    ::Faker::Config.random = Random.new(decass.defolder.to_i)

    decass.assign_attributes(
      debmcom: exist_hash["debmcom"] ? ::Faker::Lorem.sentence : nil,
      deatcom: exist_hash["deatcom"] ? ::Faker::Lorem.sentence : nil,
      dehours: exist_hash["dehours"] ? ::Faker::Number.number(1).to_d : nil
    )
  end

  # Case
  def self.white_list_case
    %w[bfkey bfddec bfcorkey bfdcn bfdocind bfpdnum bfdpdcn bforgtic bfdorg bfdnod
       bfdsoc bfd19 bf41stat bfmstat bfmpro bfdmcon bfregoff bfissnr bfrdmref bfcasev
       bfboard bfbsasgn bfattid bfdasgn bfdqrsnt bfdlocin bfdloout
       bfstasgn bfcurloc bfnrcopy bfmemid bfdmem bfnrci bfcallup bfcallyymm bfhines bfdcfld1
       bfdcfld2 bfdcfld3 bfac bfdc bfha bfms bfoc bfsh bfso bfhr bfst bfdrodec bfssoc1
       bfssoc2 bfssoc3 bfssoc4 bfssoc5 bfdtb bftbind bfdcue bfdvin bfdvout bfddro bfdroid bfddvwrk
       bfddvdsp bfddvret bfdrortr bfro1 bflot bfbox bfdtbready bfarc bfdarcin bfdarcout bfarcdisp
       bfsub bfdcertool]
  end

  def self.sanitize_case(vacols_case, _exist_hash, _record_index)
    ::Faker::Config.random = Random.new(vacols_case.bfkey.to_i)

    vacols_case.assign_attributes(
      bfcorlid: ::Faker::Number.number(9) + "S",
      bfcclkid: ::Faker::Number.number(7)
    )
  end
end

# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
