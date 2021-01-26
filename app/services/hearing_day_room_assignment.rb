# frozen_string_literal: true

class HearingDayRoomAssignment
  def initialize(request_type:, assign_room: nil, scheduled_for:, room:)
    @request_type = request_type
    # if assign_room is nil, then this was invoked by judge algorithm
    @assign_room = assign_room.nil? ? false : ActiveRecord::Type::Boolean.new.deserialize(assign_room)
    @scheduled_for = scheduled_for
    @room = room
  end

  def rooms_are_available?
    !available_room.nil?
  end

  def available_room
    @available_room ||= if !assign_room # assigning a room is not required, so set to blank string
                          room || ""
                        elsif request_type == HearingDay::REQUEST_TYPES[:central]
                          first_available_central_room
                        elsif request_type == HearingDay::REQUEST_TYPES[:video]
                          first_available_video_room
                        end
  end

  private

  attr_reader :room, :assign_room, :scheduled_for, :request_type

  def first_available_central_room
    room_count = hearing_count_by_room["2"] || 0
    "2" if room_count == 0
  end

  def first_available_video_room
    (1..HearingRooms::ROOMS.size)
      .detect do |room_number|
        room_count = hearing_count_by_room[room_number.to_s] || 0
        room_number != 2 && room_count == 0
      end
      &.to_s
  end

  def hearing_count_by_room
    @hearing_count_by_room ||= HearingDay
      .where(scheduled_for: scheduled_for)
      .group(:room)
      .count
  end
end
