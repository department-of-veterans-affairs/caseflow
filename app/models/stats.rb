##
# Stats is an interface to quickly access statistics for Caseflow Certification
# it is responsible for aggregating and caching statistics.
#
class Stats < Caseflow::Stats
  CALCULATIONS = {
    # active_users: lambda do |range|
    # end,

    certifications_started: lambda do |range|
      Certification.where(form8_started_at: range).count
    end,

    certifications_completed: lambda do |range|
      Certification.where(completed_at: range).count
    end,

    same_period_completions: lambda do |range|
      Certification.completed.where(form8_started_at: range).count
    end,

    missing_doc_same_period_completions: lambda do |range|
      Certification.was_missing_doc.merge(Certification.completed).where(form8_started_at: range).count
    end,

    time_to_certify: lambda do |range|
      Stats.percentile(:time_to_certify, Certification.where(completed_at: range), 95)
    end,

    missing_doc_time_to_certify: lambda do |range|
      Stats.percentile(:time_to_certify, Certification.was_missing_doc.where(form8_started_at: range), 95)
    end,

    median_time_to_certify: lambda do |range|
      Stats.percentile(:time_to_certify, Certification.where(completed_at: range), 50)
    end,

    median_missing_doc_time_to_certify: lambda do |range|
      Stats.percentile(:time_to_certify, Certification.was_missing_doc.where(form8_started_at: range), 50)
    end,

    missing_doc: lambda do |range|
      Certification.was_missing_doc.where(form8_started_at: range).count
    end,

    missing_nod: lambda do |range|
      Certification.was_missing_nod.where(form8_started_at: range).count
    end,

    missing_soc: lambda do |range|
      Certification.was_missing_soc.where(form8_started_at: range).count
    end,

    missing_ssoc: lambda do |range|
      Certification.was_missing_ssoc.where(form8_started_at: range).count
    end,

    ssoc_required: lambda do |range|
      Certification.ssoc_required.where(form8_started_at: range).count
    end,

    missing_form9: lambda do |range|
      Certification.was_missing_form9.where(form8_started_at: range).count
    end
  }.freeze
end
