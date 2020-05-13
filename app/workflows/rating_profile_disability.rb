# frozen_string_literal: true

# thin layer on top of a BGS rating profile disability hash

# example disability hash shape:
#   {
#     dis_sn: ...,
#     dis_dt: ...,
#     disability_evaluation: [
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
    @evaluations = Array.wrap(self[:disability_evaluations] || self[:disability_evaluation])
  end

  def evaluations_sorted_most_recent_to_oldest
    @evaluations_sorted_most_recent_to_oldest ||= evaluations.sort_by do |evaluation|
      evaluation[:conv_begin_dt] || evaluation[:begin_dt] || evaluation[:dis_dt] || Time.zone.local(0)
    end.reverse
  end

  # walk through the evaluations, sorted most recent to oldest, and return the first rating percent found
  def most_recent_prcnt_no
    evaluations_sorted_most_recent_to_oldest
      .find { |evaluation| evaluation[:prcnt_no] }
      &.send(:[], :prcnt_no)
  end

  # return the dgnstc_tc field of the most recent evaluation
  def most_recent_dgnstc_tc
    evaluations_sorted_most_recent_to_oldest.first&.send(:[], :dgnstc_tc)
  end
end
