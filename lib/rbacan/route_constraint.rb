module Rbacan
  class RouteConstraint
    # Constrains routes to users that have a given role or permission.
    #
    # Usage in config/routes.rb:
    #   constraints Rbacan::RouteConstraint.new(role: :admin) do
    #     namespace :admin do
    #       resources :users
    #     end
    #   end
    #
    #   constraints Rbacan::RouteConstraint.new(permission: :access_admin_panel) do
    #     ...
    #   end
    def initialize(role: nil, permission: nil)
      if role.nil? && permission.nil?
        raise ArgumentError, "Provide exactly one of role: or permission:"
      end
      if role && permission
        raise ArgumentError, "Provide exactly one of role: or permission:, not both"
      end

      @role       = role&.to_s
      @permission = permission&.to_s
    end

    def matches?(request)
      user = current_user_from(request)
      return false unless user

      @role ? user.has_role?(@role) : user.can?(@permission)
    end

    private

    def current_user_from(request)
      # Warden (Devise) path — most common, no extra query needed.
      warden = request.env['warden']
      return warden.user if warden&.authenticated?

      # Fallback: manual session lookup for apps not using Warden.
      user_id = request.session[:user_id] || request.session['user_id']
      return nil unless user_id

      Rbacan.permittable_class.constantize.find_by(id: user_id)
    rescue StandardError
      nil
    end
  end
end
