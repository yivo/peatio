class Member
  module Levels
    class << self
      def from_numerical_barong_level(num)
        case num
          when 1 then :email_verified
          when 2 then :phone_verified
          when 3 then :identity_verified
          else :unverified
        end
      end
    end
  end
end
