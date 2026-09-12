module Rbacan
  module ViewHelpers
    # Renders the block only when the host authorization adapter permits it.
    def authorized?(permission, context: nil, &block)
      allowed = if Rbacan.legacy_mode
                  current_user&.can?(permission.to_s)
                else
                  Rbacan.authorized?(
                    user: current_user,
                    permission: permission,
                    context: context || rbacan_authorization_context
                  )
                end
      return unless allowed

      capture(&block) if block_given?
    end
  end
end
