module Constants::CoLocatedTeams
  USERS = {
    preprod: %w[CF_KIRK_317],
    uat: %w[CF_SPOCK_317 CF_KHAN_397],
    test: %w[BVATEST1 BVATEST2 BVATEST3],
    development: %w[BVALSPORER],
    prod: %w[BVADFLEMMINGS BVADOSBORNE BVAANJOHNSON]
  }.freeze
end
