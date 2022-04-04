# NOTE: This could probably be removed, but I don't have the time at the moment
#       determine that.  It is used by signature.rb, and these methods used to 
#       be in Savon.
#
module Akami
  module CoreExt
    module Hash

      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      def deep_merge(other_hash)
        dup.deep_merge!(other_hash)
      end

      # Returns a new Hash with +self+ and +other_hash+ merged recursively.
      # Modifies the receiver in place.
      def deep_merge!(other_hash)
        other_hash.each_pair do |k,v|
          tv = self[k]
          self[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
        end
        self
      end unless defined? deep_merge!
    end
  end
end

Hash.send :include, Akami::CoreExt::Hash
