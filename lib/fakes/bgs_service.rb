class Fakes::BGSService
  def get_eps(veteran_id)
    [{
      decision_date: '01/02/2016',
      claim_type_code: '172GRANT',
      status: 'Pending'
    },
    {
      decision_date: '03/04/2016',
      claim_type_code: '170RMD',
      status: 'Cleared'
    },
    {
      decision_date: '05/06/2016',
      claim_type_code: '172BVAG',
      status: 'Pending'
    }]
  end
end
