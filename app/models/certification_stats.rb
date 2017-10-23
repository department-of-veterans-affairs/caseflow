##
# CertificationStats is an interface to quickly access statistics for Caseflow Certification
# it is responsible for aggregating and caching statistics.
#
class CertificationStats < Caseflow::Stats
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

    missing_doc_same_period_completions: lambda do |range|
      Certification.v2.was_missing_doc.merge(Certification.v2.completed).where(created_at: range).count
    end,

    time_to_certify: lambda do |range|
      CertificationStats.percentile(:time_to_certify, Certification.v2.where(completed_at: range), 95)
    end,

    missing_doc_time_to_certify: lambda do |range|
      CertificationStats.percentile(:time_to_certify, Certification.v2.was_missing_doc.where(created_at: range), 95)
    end,

    median_time_to_certify: lambda do |range|
      CertificationStats.percentile(:time_to_certify, Certification.v2.where(completed_at: range), 50)
    end,

    median_missing_doc_time_to_certify: lambda do |range|
      CertificationStats.percentile(:time_to_certify, Certification.v2.was_missing_doc.where(created_at: range), 50)
    end,

    missing_doc: lambda do |range|
      Certification.v2.was_missing_doc.where(created_at: range).count
    end,

    missing_nod: lambda do |range|
      Certification.v2.was_missing_nod.where(created_at: range).count
    end,

    missing_soc: lambda do |range|
      Certification.v2.was_missing_soc.where(created_at: range).count
    end,

    missing_ssoc: lambda do |range|
      Certification.v2.was_missing_ssoc.where(created_at: range).count
    end,

    ssoc_required: lambda do |range|
      Certification.v2.ssoc_required.where(created_at: range).count
    end,

    missing_form9: lambda do |range|
      Certification.v2.was_missing_form9.where(created_at: range).count
    end
  }.freeze
end
