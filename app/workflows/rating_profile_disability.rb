# frozen_string_literal: true

# thin layer on top of a BGS rating profile disability hash

# example disability hash shape:
#   {
#     dis_sn: ...,
#     dis_dt: ...,
#     disability_evaluations: [
#       {
#         dgnstc_tc: ...,
#         prcnt_no: ...,
#         conv_begin_dt: ...,
#         begin_dt: ...,
#         dis_dt: ...,
#         ...
#       },
#       {
#         dgnstc_tc: ...,
#         prcnt_no: ...,
#         conv_begin_dt: ...,
#         begin_dt: ...,
#         dis_dt: ...,
#         ...
#       },
#       ...
#     ],
#     ...
#   },

class RatingProfileDisability < SimpleDelegator
  def evaluations
    @evaluations ||= Array.wrap(self[:disability_evaluations] || self[:disability_evaluation])
  end

  def most_recent_evaluation
    @most_recent_evaluation ||= evaluations.max_by do |evaluation|
      evaluation[:conv_begin_dt] || evaluation[:begin_dt] || evaluation[:dis_dt] || Time.zone.local(0)
    end
  end

  def special_issues
    @special_issues ||= Array.wrap(self[:disability_special_issues])
  end
end
