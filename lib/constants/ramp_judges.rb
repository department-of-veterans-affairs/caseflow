#:nocov:
module Constants::RampJudges
  USERS = {
    preprod: %w[],
    uat: %w[],
    test: %w[],
    development: %w[BVAAABSHIRE BVAOFRANECKI BVAJWEHNER],
    # rubocop:disable Metrics/LineLength
    prod: %w[BVAJHWA BVABKNOPE BVAGWASIK BVAKBCONNER BVALHOWELL VACOWHITEY BVACFLEMING BVABMULLINS BVAKALIBRAN BVAVCHIAPP BVAAISHIZ BVASBELCHER VACOCARACA BVADJOHNSON BVAEVPAREDEZ BVALREIN]
    # rubocop:enable Metrics/LineLength
  }.freeze
end
#:nocov:
