class VACOLS::Representative < VACOLS::Record
  self.table_name = "vacols.rep"
  self.primary_key = "repkey"

  class InvalidRepTypeError < StandardError; end

  def self.update_vacols_rep_type!(bfkey:, rep_type:)
    fail(InvalidRepTypeError) unless VACOLS::CASE::REPRESENTATIVES.include?(rep_type)

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
          UPDATE REP
          SET REPFIRST = #{first_name},
              REPMI = #{middle_initial},
              REPLAST = #{last_name}
          WHERE REPKEY = #{case_id}
        SQL
      end
    end
  end

  def self.update_vacols_rep_address_one!(bfkey:, address_one:)
    conn = connection

    address_one = conn.quote(address_one)
    case_id = conn.quote(bfkey)

    MetricsService.record("VACOLS: update_vacols_rep_address_one! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_address_one") do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE REP
          SET REPADDR1 = #{address_one}
          WHERE REPKEY = #{case_id}
        SQL
      end
    end
  end
end
