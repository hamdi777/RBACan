require 'active_support/concern'

module Rbacan
  module Authorization
    extend ActiveSupport::Concern

    included do
      helper_method :authorized? if respond_to?(:helper_method)
    end

    # Calls the unauthorized handler if current_user lacks the given permission.
    def authorize!(permission)
      unless current_user&.can?(permission.to_s)
        _handle_unauthorized(permission: permission.to_s)
      end
    end

    # Calls the unauthorized handler if current_user lacks the given role.
    def authorize_role!(role)
      unless current_user&.has_role?(role.to_s)
        _handle_unauthorized(role: role.to_s)
      end
    end

    private

    def _handle_unauthorized(permission: nil, role: nil)
      handler = Rbacan.unauthorized_handler

      case handler
      when :raise
        raise Rbacan::NotAuthorized.new(nil, permission: permission, role: role)
      when :redirect
        redirect_to Rbacan.unauthorized_redirect_path,
                    alert: Rbacan::NotAuthorized.new(nil, permission: permission, role: role).message
      else
        if handler.respond_to?(:call)
          handler.call(self, permission: permission, role: role)
        else
          raise ArgumentError,
                "Rbacan.unauthorized_handler must be :raise, :redirect, or a callable. Got: #{handler.inspect}"
        end
      end
    end
  end
end
