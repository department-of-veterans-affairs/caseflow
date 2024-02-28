# frozen_string_literal: true

describe PtcpntPersnIdDepntOrgFixJob, :postgres do
  it_behaves_like "a Master Scheduler serializable object", PtcpntPersnIdDepntOrgFixJob
end
