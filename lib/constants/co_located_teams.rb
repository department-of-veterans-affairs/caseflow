module Constants::CoLocatedTeams
  USERS = {
    preprod: %w[CASEFLOW_283 CASEFLOW_317],
    uat: %w[CF_SPOCK_317 CF_KHAN_397],
    test: %w[BVATEST1 BVATEST2 BVATEST3],
    development: [],
    prod: %w[BVADFLEMMINGS BVADOSBORNE BVAANJOHNSON]
  }.freeze
end
