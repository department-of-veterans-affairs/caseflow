# frozen_string_literal: true

class Hearings::TravelBoardScheduleSerializer < ActiveModel::Serializer
  attribute :tbyear
  attribute :tbtrip
  attribute :tbleg
  attribute :tbro
  attribute :tbstdate
  attribute :tbenddate
  attribute :tbmem1
  attribute :tbmem2
  attribute :tbmem3
  attribute :tbmem4
  attribute :tbaty1
  attribute :tbaty2
  attribute :tbaty3
  attribute :tbaty4
  attribute :tbadduser
  attribute :tbaddtime
  attribute :tbmoduser
  attribute :tbmodtime
  attribute :tbcancel
  attribute :tbbvapoc
  attribute :tbropoc
end
