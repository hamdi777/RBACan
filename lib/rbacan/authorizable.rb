require 'active_support/concern'

module Rbacan
  module Authorizable
    extend ActiveSupport::Concern

    def can?(permission, context:)
      Rbacan.authorized?(user: self, permission: permission, context: context)
    end

    def has_role?(role, context:)
      Rbacan.authorized?(user: self, role: role, context: context)
    end
  end
end
