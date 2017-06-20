##
# CertificationStats is an interface to quickly access statistics for Caseflow Certification
# it is responsible for aggregating and caching statistics.
#
class CertificationV2Stats < Caseflow::Stats
  CALCULATIONS = {
    certifications_started: lambda do |range|
      Certification.v2.where(created_at: range).count
    end,

    certifications_completed: lambda do |range|
      Certification.v2.where(completed_at: range).count
    end,

    same_period_completions: lambda do |range|
      Certification.v2.completed.where(created_at: range).count
    end,

    time_to_certify: lambda do |range|
      CertificationV2Stats.percentile(:time_to_certify, Certification.v2.where(completed_at: range), 95)
    end,

    median_time_to_certify: lambda do |range|
      CertificationV2Stats.percentile(:time_to_certify, Certification.v2.where(completed_at: range), 50)
    end
  }.freeze
end
