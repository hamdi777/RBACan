require 'active_support/concern'
require 'i18n'

module Rbacan
  module Authorization
    extend ActiveSupport::Concern

    # Calls the unauthorized handler if current_user lacks the given permission.
    def authorize!(permission, context: nil)
      allowed = if Rbacan.legacy_mode
                  current_user&.can?(permission.to_s)
                else
                  Rbacan.authorized?(
                    user: current_user,
                    permission: permission,
                    context: context || rbacan_authorization_context
                  )
                end

      unless allowed
        _handle_unauthorized(permission: permission.to_s)
      end
    end

    # Calls the unauthorized handler if current_user lacks the given role.
    def authorize_role!(role, context: nil)
      allowed = if Rbacan.legacy_mode
                  current_user&.has_role?(role.to_s)
                else
                  Rbacan.authorized?(
                    user: current_user,
                    role: role,
                    context: context || rbacan_authorization_context
                  )
                end

      unless allowed
        _handle_unauthorized(role: role.to_s)
      end
    end

    private

    def rbacan_authorization_context
      raise Rbacan::ConfigurationError,
            'authorization context is required; define rbacan_authorization_context in the host controller'
    end

    def _handle_unauthorized(permission: nil, role: nil)
      handler = Rbacan.unauthorized_handler

      case handler
      when :raise
        raise Rbacan::NotAuthorized.new(nil, permission: permission, role: role)
      when :redirect
        error = Rbacan::NotAuthorized.new(nil, permission: permission, role: role)
        alert = if Rbacan.legacy_mode
                  error.message
                else
                  I18n.t(error.code, permission: permission, role: role, raise: true)
                end
        redirect_to Rbacan.unauthorized_redirect_path,
                    alert: alert
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
