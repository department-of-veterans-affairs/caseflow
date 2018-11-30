class AmaHearingDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO
  def distribute_appeals(distribution, priority, genpop: "any", limit: 1); end
end
