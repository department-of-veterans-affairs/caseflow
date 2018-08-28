class UserRepository
  class << self
    def user_info_from_vacols(css_id)
      staff_record = VACOLS::Staff.find_by(sdomainid: css_id)
      {
        uniq_id: vacols_uniq_id(staff_record),
        roles: vacols_roles(staff_record),
        attorney_id: vacols_attorney_id(staff_record),
        group_id: vacols_group_id(staff_record),
        full_name: vacols_full_name(staff_record)
      }
    end

    def user_info_for_idt(css_id)
      staff_record = VACOLS::Staff.find_by(sdomainid: css_id)
      return {} unless staff_record
      {
        first_name: staff_record.snamef,
        middle_name: staff_record.snamemi,
        last_name: staff_record.snamel,
        attorney_id: vacols_attorney_id(staff_record),
        judge_status: judge_status(staff_record),
        css_id: css_id
      }
    end

    def can_access_task?(css_id, vacols_id)
      unless QueueRepository.tasks_for_user(css_id).map(&:vacols_id).include?(vacols_id)
        msg = "User with css ID #{css_id} cannot access task with vacols ID: #{vacols_id}"
        fail Caseflow::Error::UserRepositoryError, msg
      end
      true
    end

    def css_ids_by_vlj_ids(vlj_ids)
      VACOLS::Staff.new(snamef: "Karen", snamel: "Alibrando", sattyid: "398", sdomainid: "BVAKALIBRAN").save!
      VACOLS::Staff.new(snamef: "Dorilyn", snamel: "Ames", sattyid: "871", sdomainid: "BVADAMES").save!
      VACOLS::Staff.new(snamef: "Marjorie", snamel: "Auer", sattyid: "008", sdomainid: "BVAMAUER").save!
      VACOLS::Staff.new(snamef: "Kathy", snamel: "Banfield", sattyid: "797", sdomainid: "BVAKBANFIELD").save!
      VACOLS::Staff.new(snamef: "Lisa", snamel: "Barnard", sattyid: "323", sdomainid: "BVALBARNARD").save!
      VACOLS::Staff.new(snamef: "Simone", snamel: "Belcher-Mays", sattyid: "653", sdomainid: "BVASBELCHER").save!
      VACOLS::Staff.new(snamef: "Derek", snamel: "Brown", sattyid: "048", sdomainid: "BVADBROWN").save!
      VACOLS::Staff.new(snamef: "Sonnet", snamel: "Bush", sattyid: "809", sdomainid: "BVASBUSH").save!
      VACOLS::Staff.new(snamef: "Angel", snamel: "Caracciolo", sattyid: "1939", sdomainid: "VACOCARACA").save!
      VACOLS::Staff.new(snamef: "Vincent", snamel: "Chiappetta", sattyid: "1093", sdomainid: "BVAVCHIAPP").save!
      VACOLS::Staff.new(snamef: "Vito", snamel: "Clementi", sattyid: "571", sdomainid: "BVAVCLEMENT").save!
      VACOLS::Staff.new(snamef: "Kelly", snamel: "Conner", sattyid: "541", sdomainid: "BVAKBCONNER").save!
      VACOLS::Staff.new(snamef: "Barbara", snamel: "Copeland", sattyid: "036", sdomainid: "BVABBCOPELD").save!
      VACOLS::Staff.new(snamef: "Paula", snamel: "Dilorenzo", sattyid: "438", sdomainid: "BVAPMLYNCH").save!
      VACOLS::Staff.new(snamef: "Nathaniel", snamel: "Doan", sattyid: "918", sdomainid: "BVANDOAN").save!
      VACOLS::Staff.new(snamef: "Rebecca", snamel: "Feinberg", sattyid: "790", sdomainid: "BVARFEINBERG").save!
      VACOLS::Staff.new(snamef: "Caroline", snamel: "Fleming", sattyid: "1006", sdomainid: "BVACFLEMING").save!
      VACOLS::Staff.new(snamef: "John", snamel: "Francis", sattyid: "881", sdomainid: "BVAJFRANCIS").save!
      VACOLS::Staff.new(snamef: "Caryn", snamel: "Graham", sattyid: "471", sdomainid: "BVAMCGRAHAM").save!
      VACOLS::Staff.new(snamef: "Kristi", snamel: "Gunn", sattyid: "915", sdomainid: "BVAKGUNN").save!
      VACOLS::Staff.new(snamef: "Donnie", snamel: "Hachey", sattyid: "824", sdomainid: "BVADHACHEY").save!
      VACOLS::Staff.new(snamef: "Kristin", snamel: "Haddock", sattyid: "1118", sdomainid: "BVAKHADDOCK").save!
      VACOLS::Staff.new(snamef: "Jonathan", snamel: "Hager", sattyid: "778", sdomainid: "BVAJHAGER").save!
      VACOLS::Staff.new(snamef: "Milo", snamel: "Hawley", sattyid: "256", sdomainid: "BVAMHAWLEY").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Herman", sattyid: "533", sdomainid: "BVAMHERMAN").save!
      VACOLS::Staff.new(snamef: "Linda", snamel: "Howell", sattyid: "556", sdomainid: "BVALHOWELL").save!
      VACOLS::Staff.new(snamef: "Jennifer", snamel: "Hwa", sattyid: "947", sdomainid: "BVAJHWA").save!
      VACOLS::Staff.new(snamef: "Marti", snamel: "Hyland", sattyid: "750", sdomainid: "BVAMHYLAND").save!
      VACOLS::Staff.new(snamef: "Amy", snamel: "Ishizawar", sattyid: "1010", sdomainid: "BVAAISHIZ").save!
      VACOLS::Staff.new(snamef: "Anne", snamel: "Jaeger", sattyid: "784", sdomainid: "BVAAJAEGER").save!
      VACOLS::Staff.new(snamef: "Lana", snamel: "Jeng", sattyid: "845", sdomainid: "BVALJENG").save!
      VACOLS::Staff.new(snamef: "Dana", snamel: "Johnson", sattyid: "895", sdomainid: "BVADJOHNSON").save!
      VACOLS::Staff.new(snamef: "Michelle", snamel: "Kane", sattyid: "598", sdomainid: "BVAMLKANE").save!
      VACOLS::Staff.new(snamef: "Karen", snamel: "Kennerly", sattyid: "801", sdomainid: "BVAKKENNERLY").save!
      VACOLS::Staff.new(snamef: "Ryan", snamel: "Kessel", sattyid: "872", sdomainid: "BVARKESSEL").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Kilcoyne", sattyid: "319", sdomainid: "BVAMKILCOYN").save!
      VACOLS::Staff.new(snamef: "Bradley", snamel: "Knope", sattyid: "1070", sdomainid: "BVABKNOPE").save!
      VACOLS::Staff.new(snamef: "Kelli", snamel: "Kordich", sattyid: "647", sdomainid: "BVAKKORDICH").save!
      VACOLS::Staff.new(snamef: "Jonathan", snamel: "Kramer", sattyid: "627", sdomainid: "BVAJBKRAMER").save!
      VACOLS::Staff.new(snamef: "Simone", snamel: "Krembs", sattyid: "840", sdomainid: "BVASKREMBS").save!
      VACOLS::Staff.new(snamef: "Nathan", snamel: "Kroes", sattyid: "955", sdomainid: "BVANKROES").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Lane", sattyid: "654", sdomainid: "BVAMLANE").save!
      VACOLS::Staff.new(snamef: "Mary", snamel: "Larkin", sattyid: "464", sdomainid: "BVAMELARKIN").save!
      VACOLS::Staff.new(snamef: "Eric", snamel: "Leboff", sattyid: "731", sdomainid: "BVAESLEBOFF").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Lyon", sattyid: "115", sdomainid: "BVAMDLYON").save!
      VACOLS::Staff.new(snamef: "Andrew", snamel: "Mackenzie", sattyid: "559", sdomainid: "BVAAMACKEN").save!
      VACOLS::Staff.new(snamef: "Anthony", snamel: "Mainelli", sattyid: "611", sdomainid: "BVAAMAINELLI").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Martin", sattyid: "332", sdomainid: "BVAMMARTIN").save!
      VACOLS::Staff.new(snamef: "Kerri", snamel: "Millikan", sattyid: "876", sdomainid: "BVAKMILLIKAN").save!
      VACOLS::Staff.new(snamef: "Jacqueline", snamel: "Monroe", sattyid: "418", sdomainid: "BVAJMONROE").save!
      VACOLS::Staff.new(snamef: "Victoria", snamel: "Moshiashwili", sattyid: "1591", sdomainid: "BVAVMOSHI").save!
      VACOLS::Staff.new(snamef: "Bobby", snamel: "Mullins", sattyid: "1024", sdomainid: "BVABMULLINS").save!
      VACOLS::Staff.new(snamef: "Thomas", snamel: "O Shay", sattyid: "595", sdomainid: "BVATOSHAY").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Pappas", sattyid: "346", sdomainid: "BVAMAPAPPAS").save!
      VACOLS::Staff.new(snamef: "Kalpana", snamel: "Parakkal", sattyid: "458", sdomainid: "BVAKPARAKAL").save!
      VACOLS::Staff.new(snamef: "Jeffrey", snamel: "Parker", sattyid: "460", sdomainid: "BVAJPARKER").save!
      VACOLS::Staff.new(snamef: "Ursula", snamel: "Powell", sattyid: "153", sdomainid: "BVAURPOWELL").save!
      VACOLS::Staff.new(snamef: "Lesley", snamel: "Rein", sattyid: "846", sdomainid: "BVALREIN").save!
      VACOLS::Staff.new(snamef: "James", snamel: "Reinhart", sattyid: "894", sdomainid: "BVAJREINHART").save!
      VACOLS::Staff.new(snamef: "Steven", snamel: "Reiss", sattyid: "467", sdomainid: "BVASDREISS").save!
      VACOLS::Staff.new(snamef: "Tara", snamel: "Reynolds", sattyid: "748", sdomainid: "BVATKONYA").save!
      VACOLS::Staff.new(snamef: "Holly", snamel: "Seesel", sattyid: "904", sdomainid: "BVAHSEESEL").save!
      VACOLS::Staff.new(snamef: "George", snamel: "Senyk", sattyid: "225", sdomainid: "BVAGRSENYK").save!
      VACOLS::Staff.new(snamef: "Alexandra", snamel: "Simpson", sattyid: "607", sdomainid: "BVAAPSIMPSON").save!
      VACOLS::Staff.new(snamef: "Deborah", snamel: "Singleton", sattyid: "450", sdomainid: "BVADWSINGLE").save!
      VACOLS::Staff.new(snamef: "Michael", snamel: "Skaltsounis", sattyid: "550", sdomainid: "BVAMJSKALT").save!
      VACOLS::Staff.new(snamef: "Tanya", snamel: "Smith", sattyid: "738", sdomainid: "BVATASMITH").save!
      VACOLS::Staff.new(snamef: "Paul", snamel: "Sorisio", sattyid: "909", sdomainid: "BVAPSORISIO").save!
      VACOLS::Staff.new(snamef: "Mary", snamel: "Sorisio", sattyid: "875", sdomainid: "BVAMSORISIO").save!
      VACOLS::Staff.new(snamef: "Gayle", snamel: "Strommen", sattyid: "586", sdomainid: "VACOSTROMG").save!
      VACOLS::Staff.new(snamef: "Matthew", snamel: "Tenner", sattyid: "728", sdomainid: "BVAMTENNER").save!
      VACOLS::Staff.new(snamef: "Estela", snamel: "Velez", sattyid: "842", sdomainid: "BVAEVPAREDEZ").save!
      VACOLS::Staff.new(snamef: "Helena", snamel: "Walker", sattyid: "981", sdomainid: "BVAHWALKER").save!
      VACOLS::Staff.new(snamef: "Glenn", snamel: "Wasik", sattyid: "561", sdomainid: "BVAGWASIK").save!
      VACOLS::Staff.new(snamef: "David", snamel: "Wight", sattyid: "657", sdomainid: "BVADWIGHT").save!
      VACOLS::Staff.new(snamef: "Jessica", snamel: "Zissimos", sattyid: "776", sdomainid: "BVAJWILLS").save!





      users = VACOLS::Staff.where(sattyid: vlj_ids)

      results = {}
      users.each do |user|
        results.merge!(user.sattyid => { css_id: user.sdomainid,
                                         first_name: user.snamef,
                                         last_name: user.snamel })
      end
      results
    end

    # This method is only used in dev/demo mode to test the judge spreadsheet functionality in hearing scheduling
    # :nocov:
    def create_judge_in_vacols(first_name, last_name, vlj_id)
      return unless Rails.env.development? || Rails.env.demo?

      css_id = ["BVA", first_name.first, last_name].join
      VACOLS::Staff.create(snamef: first_name, snamel: last_name, sdomainid: css_id, sattyid: vlj_id)
    end

    def css_id_by_full_name(full_name)
      name = full_name.split(" ")
      first_name = name.first
      last_name = name.last
      staff = VACOLS::Staff.where("snamef LIKE ? and snamel LIKE ?", "%#{first_name}%", "%#{last_name}%")
      if staff.size > 1
        staff = VACOLS::Staff.where(snamef: first_name, snamel: last_name)
      end
      staff.first.try(:sdomainid)
    end
    # :nocov:

    private

    def roles_based_on_staff_fields(staff_record)
      case staff_record.svlj
      when "J"
        ["judge"]
      when "A"
        staff_record.sattyid ? %w[attorney judge] : ["judge"]
      when nil
        check_other_staff_fields(staff_record)
      else
        []
      end
    end

    def judge_status(staff_record)
      case staff_record.svlj
      when "J"
        "judge"
      when "A"
        "acting judge"
      else
        "none"
      end
    end

    def check_other_staff_fields(staff_record)
      return ["attorney"] if staff_record.sattyid
      return ["colocated"] if staff_record.stitle == "A1" || staff_record.stitle == "A2"
      []
    end

    def vacols_uniq_id(staff_record)
      staff_record.try(:slogid)
    end

    # STAFF.SVLJ = 'J' indicates a user is a Judge, the field may also have an 'A' which indicates an Acting judge.
    # If the STAFF.SVLJ is nil and STAFF.SATTYID is not nil then it is an attorney.
    def vacols_roles(staff_record)
      return roles_based_on_staff_fields(staff_record) if staff_record
      []
    end

    # :nocov:
    def vacols_attorney_id(staff_record)
      staff_record.try(:sattyid)
    end

    def vacols_group_id(staff_record)
      staff_record.try(:stitle) || ""
    end

    def vacols_full_name(staff_record)
      if staff_record
        FullName.new(staff_record.snamef, staff_record.snamemi, staff_record.snamel).formatted(:readable_full)
      end
    end
    # :nocov:
  end
end
