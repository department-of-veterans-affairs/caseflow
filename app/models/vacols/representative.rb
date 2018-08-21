class VACOLS::Representative < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rep"
  self.primary_key = "repkey"

  class InvalidRepTypeError < StandardError; end

  # mapping of values in REP.REPTYPE
  ACTIVE_REPTYPES = {
    appellant_attorney: { code: "A", name: "Attorney" },
    appellant_agent: { code: "G", name: "Agent" },
    # :fee_agreement: "F", # deprecated
    contesting_claimant: { code: "C", name: "Contesting Claimant" },
    contesting_claimant_attorney: { code: "D", name: "Contesting Claimant's Attorney" },
    contesting_claimant_agent: { code: "E", name: "Contesting Claimant's Agent" }
    # :fee_attorney_reference_list: "R", # deprecated
  }.freeze

  def self.reptype_name_from_code(reptype)
    ACTIVE_REPTYPES.values.find { |obj| obj[:code] == reptype }.try(:[], :name)
  end

  def self.representatives(bfkey)
    where(repkey: bfkey, reptype: ACTIVE_REPTYPES.values.map { |v| v[:code] })
  end

  def self.appellant_reptypes
    [ACTIVE_REPTYPES[:appellant_attorney][:code], ACTIVE_REPTYPES[:appellant_agent][:code]]
  end

  def self.appellant_representative(bfkey)
    # In rare cases, there may be more than one result for this query. If so, return the most recent one.
    # TODO: for Queue use cases, we should return all appellant representatives
    where(repkey: bfkey, reptype: appellant_reptypes).order("repaddtime DESC").first
  end

  def self.update_vacols_rep_type!(bfkey:, rep_type:)
    fail(InvalidRepTypeError) unless VACOLS::Case::REPRESENTATIVES.include?(rep_type)

    conn = connection

    rep_type = conn.quote(rep_type)
    case_id = conn.quote(bfkey)

    MetricsService.record("VACOLS: update_vacols_rep_type! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_type") do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE BRIEFF
          SET BFSO = #{rep_type}
          WHERE BFKEY = #{case_id}
        SQL
      end
    end
  end

  def self.update_vacols_rep_name!(bfkey:, first_name:, middle_initial:, last_name:)
    conn = connection
    first_name = conn.quote(first_name)
    middle_initial = conn.quote(middle_initial)
    last_name = conn.quote(last_name)
    case_id = conn.quote(bfkey)

    MetricsService.record("VACOLS: update_vacols_rep_first_name! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_first_name") do
      conn.transaction do
        conn.execute(<<-SQL)
          MERGE INTO REP USING dual ON ( REPKEY=#{case_id} )
          WHEN MATCHED THEN
            UPDATE SET REPFIRST=#{first_name}, REPMI=#{middle_initial}, REPLAST=#{last_name}
          WHEN NOT MATCHED THEN INSERT (REPKEY, REPFIRST, REPMI, REPLAST)
            VALUES ( #{case_id}, #{first_name}, #{middle_initial}, #{last_name} )
        SQL
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.update_vacols_rep_address!(bfkey:, address:)
    conn = connection

    address_one = conn.quote(address[:address_one])
    address_two = conn.quote(address[:address_two])
    city = conn.quote(address[:city])
    state = conn.quote(address[:state])
    zip = conn.quote(address[:zip])
    case_id = conn.quote(bfkey)

    MetricsService.record("VACOLS: update_vacols_rep_address! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_address") do
      conn.transaction do
        conn.execute(<<-SQL)
          MERGE INTO REP USING dual ON ( REPKEY=#{case_id} )
          WHEN MATCHED THEN
            UPDATE
            SET REPADDR1 = #{address_one},
                REPADDR2 = #{address_two},
                REPCITY = #{city},
                REPST = #{state},
                REPZIP = #{zip}
          WHEN NOT MATCHED THEN INSERT (REPKEY, REPADDR1, REPADDR2, REPCITY, REPST, REPZIP)
            VALUES ( #{case_id}, #{address_one}, #{address_two}, #{city}, #{state}, #{zip} )
        SQL
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # :nocov:
end
