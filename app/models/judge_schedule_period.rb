# frozen_string_literal: true

##
# JudgeSchedulePeriod represents a schedule period for assigning judges to hearing days.
# This record is created after user uploads JudgeAssignment spreadsheet for a schedule period.
# Once created, it creates JudgeNonAvailability records with the blackout dates for each judge.
#
# This class is no longer used, but preserved here to make it easier to access historical database records.
##
class JudgeSchedulePeriod < SchedulePeriod; end
