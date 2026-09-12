module Rbacan
  class RouteConstraint
    def initialize(role: nil, permission: nil, user_resolver: nil, context_resolver: nil)
      if role.nil? && permission.nil?
        raise ArgumentError, 'Provide exactly one role: or permission:'
      end
      if role && permission
        raise ArgumentError, 'Provide exactly one role: or permission:, not both'
      end

      @role = role&.to_s
      @permission = permission&.to_s
      @user_resolver = user_resolver
      @context_resolver = context_resolver
    end

    def matches?(request)
      return hardened_match?(request) unless Rbacan.legacy_mode

      user = current_user_from(request)
      return false unless user

      @role ? user.has_role?(@role) : user.can?(@permission)
    end

    private

    def hardened_match?(request)
      return false unless @user_resolver&.respond_to?(:call) && @context_resolver&.respond_to?(:call)

      Rbacan.authorized?(
        user: @user_resolver.call(request),
        permission: @permission,
        role: @role,
        context: @context_resolver.call(request)
      )
    rescue Rbacan::ConfigurationError, ArgumentError
      false
    end

    def current_user_from(request)
      warden = request.env['warden']
      return warden.user if warden&.authenticated?

      user_id = request.session[:user_id] || request.session['user_id']
      return nil unless user_id

      Rbacan.permittable_class.constantize.find_by(id: user_id)
    rescue StandardError
      nil
    end
  end
end
