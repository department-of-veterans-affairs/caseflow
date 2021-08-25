# frozen_string_literal: true

class VACOLS::Representative < VACOLS::Record
  include AddressMapper

  # :nocov:
  self.table_name = "rep"
  self.primary_key = "repkey"

  attribute :repaddr1, :ascii_string, limit: 50
  attribute :repaddr2, :ascii_string, limit: 50
  attribute :repcity, :ascii_string, limit: 20
  attribute :replast, :ascii_string, limit: 40
  attribute :repfirst, :ascii_string, limit: 24
  attribute :repmi, :ascii_string, limit: 4

  class RepError < StandardError; end
  class InvalidRepTypeError < RepError; end

  # mapping of values in REP.REPTYPE
  APPELLANT_REPTYPES = {
    appellant_attorney: { code: "A", name: "Attorney" },
    appellant_agent: { code: "G", name: "Agent" }
  }.freeze
  CONTESTED_REPTYPES = {
    # :fee_agreement: "F", # deprecated
    contesting_claimant: { code: "C", name: "Contesting Claimant" },
    contesting_claimant_attorney: { code: "D", name: "Contesting Claimant's Attorney" },
    contesting_claimant_agent: { code: "E", name: "Contesting Claimant's Agent" }
    # :fee_attorney_reference_list: "R", # deprecated
  }.freeze
  ACTIVE_REPTYPES = APPELLANT_REPTYPES.merge(CONTESTED_REPTYPES).freeze

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

  def self.update_vacols_rep_table!(bfkey:, name:, address:, type:)
    fail(InvalidRepTypeError) if ACTIVE_REPTYPES[type].empty?

    MetricsService.record("VACOLS: update_vacols_rep_name! #{bfkey}",
                          service: :vacols,
                          name: "update_vacols_rep_name") do
      rep = appellant_representative(bfkey)

      # TODO: to be 100% safe, we should pass the repaddtime value
      # down to the client. It's *possible* that if a user
      # started a certification, then added a new POA row for that appeal,
      # then completed the certification, we could be updating the wrong POA row.
      # However, this is very unlikely given the way current business processes operate.
      if rep
        update_rep!(bfkey, rep.repaddtime, format_attrs(name, address, type))
      else
        create_rep!(bfkey, format_attrs(name, address, type))
      end
    end
  end

  def self.format_attrs(name, address, reptype)
    attrs = {
      reptype: ACTIVE_REPTYPES[reptype][:code]
    }
    unless name.empty?
      attrs = attrs.merge(
        repfirst: name[:first_name],
        repmi: name[:middle_initial],
        replast: name[:last_name]
      )
    end
    unless address.empty?
      attrs = attrs.merge(
        repaddr1: address[:address_one],
        repaddr2: address[:address_two],
        repcity: address[:city],
        repst: address[:state][0, 4],
        repzip: address[:zip][0, 10]
      )
    end
    attrs
  end

  def self.update_rep!(repkey, repaddtime, rep_attrs)
    # VACOLS has a unique constraint on repkey + repaddtime.
    # Ruby's date equality rules prevent us from comparing the date object
    # directly. VACOLS only stores dates, not datetimes, so
    # comparing year/month/day should be no less accurate.
    VACOLS::Representative
      .where(repkey: repkey)
      .where("extract(year  from repaddtime) = ?", repaddtime.year)
      .where("extract(month from repaddtime) = ?", repaddtime.month)
      .where("extract(day   from repaddtime) = ?", repaddtime.day)
      .update_all(rep_attrs)
  end

  def self.create_rep!(bfkey, rep_attrs)
    create!(rep_attrs.merge(repaddtime: VacolsHelper.local_date_with_utc_timezone, repkey: bfkey))
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

  def as_claimant
    type = if reptype == "C"
             "Claimant"
           elsif reptype == "D"
             "Attorney"
           elsif reptype == "E"
             "Agent"
           end

    code = repso

    {
      type: type,
      first_name: repfirst,
      middle_name: repmi,
      last_name: replast,
      name_suffix: repsuf,
      address: get_address_from_rep_entry(self),
      representative: {
        code: code,
        name: VACOLS::Case::REPRESENTATIVES.dig(code, :full_name)
      }
    }
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
