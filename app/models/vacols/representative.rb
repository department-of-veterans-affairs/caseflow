
class VACOLS::Representative < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rep"
  self.primary_key = "repkey"

  class InvalidRepTypeError < StandardError; end

  ACTIVE_REPTYPES = {
    appellant_attorney: "A",
    appellant_agent: "G",
    # :fee_agreement: "F", # deprecated
    contesting_claimant_organization: "C", 
    contesting_claimant_attorney: "D", 
    contesting_claimant_agent: "E"
    # :fee_attorney_reference_list: "R", # deprecated
  }

  def self.representatives
    VACOLS::Representative.where(repkey: bfkey, reptype: ACTIVE_REPTYPES.values)
  end

  def self.all_representatives(bfkey)
    VACOLS::Representative.where(repkey: bfkey)
  end

  def self.appellant_representative(bfkey)
    appellant_reptypes = [ACTIVE_REPTYPES[:appellant_attorney], ACTIVE_REPTYPES[:appellant_agent]]

    # In rare cases, there may be more than one result for this query. If so, return the most recent one.
    # TODO: for Queue use cases, we should return all appellant representatives
    all_representatives(bfkey).where(reptype: appellant_reptypes).order("repaddtime DESC").first
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
      rep = appellant_representative(bfkey)
      # TODO: to be 100% safe, we should pass the repaddtime value
      # down to the client. It's *possible* that if a user
      # started a certification, then added a new POA row for that appeal,
      # then completed the certification, we could be updating the wrong POA row.
      # However, this is very unlikely given the way current business processes operate.
      rep ? update_rep(bfkey, rep.repaddtime, attrs) : create_rep!(attrs)
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

      rep = appellant_representative(bfkey)
      # TODO: to be 100% safe, we should pass the repaddtime value
      # down to the client. It's *possible* that if a user
      # started a certification, then added a new POA row for that appeal,
      # then completed the certification, we could be updating the wrong POA row.
      # However, this is very unlikely given the way current business processes operate.
      rep ? update_rep(bfkey, rep.repaddtime, attrs) : create_rep!(attrs)
    end
  end

  def self.update_rep!(repkey, repaddtime, rep_attrs)
    where(repkey: repkey, repaddtime: repaddtime).update_all(rep_attrs)
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
    fail RepError, "Since the primary key is not unique, `delete` or `destroy`
      will delete all results with the same `repkey`. Use `repkey` and `repaddtime` to safely delete one record."
  end
end
