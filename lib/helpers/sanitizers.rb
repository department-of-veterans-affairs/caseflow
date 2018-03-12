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
  # Utility method to randomly either write a value, or nil
  def self.random_or_nil(value)
    return value if ::Faker::Number.number(1).to_i < 5
    nil
  end

  # Utility method to nil out values that are not white listed
  def self.white_list(record, array_of_fields)
    hash_to_nil_fields = (record.attribute_names - array_of_fields).reduce({}) do |acc, field|
      acc[field] = nil
      acc
    end

    record.assign_attributes(hash_to_nil_fields)
  end

  # Entry method that calls the given klass' white_list and sanitize methods
  def self.sanitize(klass, record)
    table_name = klass.name.split("::")[1].downcase

    white_list(record, send("white_list_#{table_name}"))
    send("sanitize_#{table_name}", record)
  end

  # Staff table
  def self.white_list_staff
    %w[stafkey susrtyp ssalut snamef snamemi snamel slogid stitle sorg sdept saddrst1
       saddrst2 saddrcty saddrstt saddrcnty saddrzip stelw stelwex stelfax stelh staduser stadtime
       stmduser stmdtime stc1 stc2 stc3 stc4 snotes sactive smemgrp
       sattyid svlj]
  end

  def self.sanitize_staff(staff)
    ::Faker::Config.random = Random.new(Digest::SHA256.hexdigest(staff.slogid).to_i(16))

    sdomainid = case staff[:stafkey]
                when "ZZHU"
                  "READER"
                when "PSORISIO"
                  "HEARING PREP"
                else
                  "FAKELOGIN" + staff.slogid
                end

    staff.assign_attributes(
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
      sdomainid: sdomainid
    )
  end

  # Travel Board
  def self.white_list_travelboardschedule
    %w[tbyear tbtrip tbleg tbro tbstdate tbenddate tbmem1 tbmem2 tbmem3 tbmem4 tbaty1 tbaty2
       tbaty3 tbaty4 tbadduser tbaddtime tbmoduser tbmodtime tbcancel tbbvapoc tbropoc]
  end

  def self.sanitize_travelboardschedule(travel_board)
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

  def self.sanitize_issref(issref)
    # Nothing to sanitize in this table
  end

  # Vftypes
  def self.white_list_vftypes
    %w[ftkey ftdesc ftadusr ftadtim ftmdusr ftmdtim ftactive fttype ftsys ftspare1 ftspare2 ftspare3]
  end

  def self.sanitize_vftypes(vftypes)
    # Nothing to sanitize in this table
  end

  # Folder
  def self.white_list_folder
    %w[ticknum ticorkey tistkey tinum tifiloc titrnum tidrecv tiddue
       tidcls tiwpptr tiaduser tiadtime timduser timdtime tiresp1 tikeywrd
       tispare1 tispare2 tisubj1 tisubj tisubj2
       tiagor tiasbt tigwui tihepc tiaids timgas tiptsd tiradb tiradn tisarc tisexh titoba tinosc
       ti38us tinnme tinwgr tipres titrtm tinoot tioctime tiocuser tidktime tidkuser tipulac
       ticerullo tivbms tiread2]
  end

  def self.sanitize_folder(folder)
    ::Faker::Config.random = Random.new(folder.ticknum.to_i)

    folder.assign_attributes(
      titrnum: ::Faker::Number.number(9) + "S",
      tinum: ::Faker::Number.number(7),
      tiwpptr: random_or_nil(::Faker::Lorem.sentence),
      tispare1: folder.tispare1 ? ::Faker::Name.last_name : nil,
      tispare2: folder.tispare2 ? ::Faker::Name.first_name : nil,
      tiread2: folder.tiread2 ? ::Fakes::Number.number(7) : nil
    )
  end

  # Representative
  def self.white_list_representative
    %w[repkey repaddtime reptype repso replast repfirst repmi repsuf repaddr1 repaddr2
       repcity repst repzip repphone repnotes repmoduser repmodtime repdirpay repdfee
       repfeerecv replastdoc repfeedisp repcorkey repacknw]
  end

  def self.sanitize_representative(representative)
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
    %w[stafkey susrtyp ssalut snamef snamemi snamel slogid stitle sorg
       sdept saddrst1 saddrst2 saddrcty saddrstt saddrcnty saddrzip stelw stelwex
       stelfax stelh staduser stadtime stmduser stmdtime snotes
       sactive sspare1 sspare2 sspare3 sspare4 ssn sfnod sdob sgender]
  end

  def self.sanitize_correspondent(correspondent)
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
      sspare1: correspondent.sspare1 ? ::Faker::Name.last_name : nil,
      sspare2: correspondent.sspare2 ? ::Faker::Name.first_name : nil,
      sspare3: correspondent.sspare3 ? ::Faker::Name.initials(1) : nil,
      sspare4: correspondent.sspare4 ? ::Faker::Name.suffix : nil,
      sfnod: correspondent.sfnod ? ::Faker::Date.between(Date.new(1980), Date.new(2018)) : nil,
      sdob: random_or_nil(::Faker::Date.between(Date.new(1960), Date.new(1990))),
      sgender: (::Faker::Number.number(1).to_i < 5) ? "M" : "F"
    )
  end

  # Issue
  def self.white_list_caseissue
    %w[isskey issseq issprog isscode isslev1 isslev2 isslev3 issdc issdcls issadtime issaduser issmdtime
       issmduser issdesc isssel issgr issdev]
  end

  def self.sanitize_caseissue(issue)
    ::Faker::Config.random = Random.new(issue.isskey.to_i)

    issue.assign_attributes(
      issdesc: ::Faker::Lorem.sentence # do better Mark
    )
  end

  # Note
  def self.white_list_note
    %w[tasknum tsktknm tskstfas tskactcd tskclass tskrqact tskrspn tskdassn tskdtc tskddue tskdcls
       tskstown tskstat tskadusr tskadtm tskmdusr tskmdtm tsactive]
  end

  def self.sanitize_note(note)
    ::Faker::Config.random = Random.new(note.tsktknm.to_i)

    note.assign_attributes(
      tskrqact: ::Faker::Lorem.sentence,
      tskrspn: random_or_nil(::Faker::Lorem.sentence)
    )
  end

  # CaseHearing
  def self.white_list_casehearing
    %w[hearing_pkseq hearing_type folder_nr hearing_date hearing_disp board_member notes1
       team room rep_state mduser mdtime reqdate clsdate recmed consent conret
       contapes tranreq transent wbtapes wbbackup wbsent recprob taskno adduser addtime
       aod holdays vdkey repname vdbvapoc vdropoc canceldate]
  end

  def self.sanitize_casehearing(hearing)
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
    %w[defolder deatty deteam depdiff defdiff deassign dereceive dehours deprod detrem dearem deoq
       deadusr deadtim deprogrev deatcom debmcom demdusr demdtim delock dememid decomp dedeadline
       deicr defcr deqr1 deqr2 deqr3 deqr4 deqr5 deqr6 deqr7 deqr8 deqr9 deqr10 deqr11 dedocid derecommend]
  end

  def self.sanitize_decass(decass)
    ::Faker::Config.random = Random.new(decass.defolder.to_i)

    decass.assign_attributes(
      debmcom: decass.debmcom ? ::Faker::Lorem.sentence : nil,
      deatcom: decass.deatcom ? ::Faker::Lorem.sentence : nil,
      dehours: decass.dehours ? ::Faker::Number.number(1).to_d : nil
    )
  end

  # Case
  def self.white_list_case
    %w[bfkey bfddec bfcorkey bfcorlid bfdcn bfdocind bfpdnum bfdpdcn bforgtic bfdorg bfdnod
       bfdsoc bfd19 bf41stat bfmstat bfmpro bfdmcon bfregoff bfissnr bfrdmref bfcasev
       bfboard bfbsasgn bfattid bfdasgn bfcclkid bfdqrsnt bfdlocin bfdloout
       bfstasgn bfcurloc bfnrcopy bfmemid bfdmem bfnrci bfcallup bfcallyymm bfhines bfdcfld1
       bfdcfld2 bfdcfld3 bfac bfdc bfha bfms bfoc bfsh bfso bfhr bfst bfdrodec bfssoc1
       bfssoc2 bfssoc3 bfssoc4 bfssoc5 bfdtb bftbind bfdcue bfdvin bfdvout bfddro bfdroid bfddvwrk
       bfddvdsp bfddvret bfdrortr bfro1 bflot bfbox bfdtbready bfarc bfdarcin bfdarcout bfarcdisp
       bfsub bfdcertool]
  end

  def self.sanitize_case(vacols_case)
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
