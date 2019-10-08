# frozen_string_literal: true

module TaskActionHelper
  def self.build_hash(config, task, user)
    return config unless config[:func]

    ret_val = TaskActionRepository.send(config[:func], task, user)

    return ret_val if ret_val&.delete(:returns_complete_hash)

    config.merge(data: ret_val)
  end
end
