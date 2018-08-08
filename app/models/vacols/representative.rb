class VACOLS::Representative < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rep"
  self.primary_keys = :repkey, :repaddtime

  class InvalidRepTypeError < StandardError; end

  ACTIVE_REPTYPES = {
    "Appellant's Attorney": "A",
    "Appellant's Agent": "G",
    # "Fee Agreement": "F", # deprecated
    "Contesting Claimant": "C", 
    "Contesting Claimant's Attorney": "D", 
    "Contesting Claimant's Agent": "E", 
    # "Fee Attorney reference list": "R", # deprecated
  }

  def self.representatives(bfkey)
    VACOLS::Representative.where(repkey: bfkey)
  end

  def self.appellant_representative
    appellant_reptypes = [REPTYPES["Appellant's Attorney"], REPTYPES["Appellant's Agent"]]

    # In rare cases, there may be more than one result for this query. If so, return the most recent one.
    representatives.where(reptype: appellant_reptypes).order("repaddtime DESC").first
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
    MetricsService.record("VACOLS: update_vacols_rep_type! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_type") do
      attrs = { repfirst: first_name, repmi: middle_initial, replast: last_name } 
      rep = get_appellant_representative(bfkey)
      rep.update!(attrs)
    rescue ActiveRecord::RecordNotFound
      create!({repkey: bfkey}.merge(attrs))
    end  
  end

  def self.update_vacols_rep_address!(bfkey:, address:)
    MetricsService.record("VACOLS: update_vacols_rep_address! #{case_id}",
                          service: :vacols,
                          name: "update_vacols_rep_address") do
      attrs = { 
        repaddr1: address[:address_one], 
        repaddr2: address[:address_two], 
        city: address[:city], 
        state: address[:state], 
        zip: address[:zip]
      } 
      rep = get_appellant_representative(bfkey)
      rep.update!(attrs)
    rescue ActiveRecord::RecordNotFound
      create!({repkey: bfkey}.merge(attrs))
    end
  end
end
