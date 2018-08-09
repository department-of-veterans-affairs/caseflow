class VACOLS::Representative < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rep"
  self.primary_key = "repkey"

  class RepError < StandardError; end
  class InvalidRepTypeError < RepError; end

  ACTIVE_REPTYPES = {
    appellant_attorney: "A",
    appellant_agent: "G",
    # :fee_agreement: "F", # deprecated
    contesting_claimant: "C", 
    contesting_claimant_attorney: "D", 
    contesting_claimant_agent: "E"
    # :fee_attorney_reference_list: "R", # deprecated
  }

  def self.representatives(bfkey)
    where(repkey: bfkey, reptype: ACTIVE_REPTYPES.values)
  end

  def self.appellant_representative(bfkey)
    appellant_reptypes = [ACTIVE_REPTYPES[:appellant_attorney], ACTIVE_REPTYPES[:appellant_agent]]

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
    MetricsService.record("VACOLS: update_vacols_rep_name! #{bfkey}",
                          service: :vacols,
                          name: "update_vacols_rep_name") do
      attrs = { repfirst: first_name, repmi: middle_initial, replast: last_name } 
      rep = appellant_representative(bfkey)
      # TODO: to be 100% safe, we should pass the repaddtime value
      # down to the client. It's *possible* that if a user
      # started a certification, then added a new POA row for that appeal,
      # then completed the certification, we could be updating the wrong POA row.
      # However, this is very unlikely given the way current business processes operate.
      rep ? update_rep!(bfkey, rep.repaddtime, attrs) : create_rep!(attrs)
    end
  end

  def self.update_vacols_rep_address!(bfkey:, address:)
    MetricsService.record("VACOLS: update_vacols_rep_address! #{bfkey}",
                          service: :vacols,
                          name: "update_vacols_rep_address") do
      attrs = { 
        repaddr1: address[:address_one], 
        repaddr2: address[:address_two], 
        repcity: address[:city], 
        repst: address[:state], 
        repzip: address[:zip]
      } 
      rep = appellant_representative(bfkey)
      # TODO: to be 100% safe, we should pass the repaddtime value
      # down to the client. It's *possible* that if a user
      # started a certification, then added a new POA row for that appeal,
      # then completed the certification, we could be updating the wrong POA row.
      # However, this is very unlikely given the way current business processes operate.
      rep ? update_rep!(bfkey, rep.repaddtime, attrs) : create_rep!(attrs)
    end
  end

  def self.update_rep!(repkey, repaddtime, rep_attrs)
    # VACOLS itself uses repkey + repaddtime as the unique key for this table,
    # so although this will select more than one row in some cases, we can't
    # really do any better than this.
    # Ruby's date equality rules prevent us from comparing the date object
    # directly. VACOLS only stores dates, not datetimes, so
    # comparing year/month/day should be no less accurate. 
    
    VACOLS::Representative.
      where(repkey: repkey).
      where('extract(year  from repaddtime) = ?', repaddtime.year).
      where('extract(month from repaddtime) = ?', repaddtime.month).
      where('extract(day   from repaddtime) = ?', repaddtime.day).
      update_all(rep_attrs)
  end  

  def self.create_rep!(rep_attrs)
    create!(rep_attrs.merge(repaddtime: VacolsHelper.local_date_with_utc_timezone))
  end

  def update(*)
    update_error_message
  end

  def update!(*)
    update_error_message
  end

  def delete
    delete_error_message
  end

  def destroy
    delete_error_message
  end

  private

  def update_error_message
    fail RepError, "Since the primary key is not unique, `update` will update all results
      with the same `repkey`. Instead use VACOLS::Representative.update_rep!
      that uses `repkey` and `repaddtime` to safely update one record."
  end

  def delete_error_message
    fail RepError, "Since the primary key is not unique, `delete` will delete all results
      with the same `repkey`. Instead, use `repkey` and `repaddtime` to safely update one record."
  end
end
