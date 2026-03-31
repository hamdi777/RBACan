module Rbacan
  class NotAuthorized < StandardError
    attr_reader :permission, :role

    def initialize(message = nil, permission: nil, role: nil)
      @permission = permission
      @role       = role
      super(message || default_message)
    end

    private

    def default_message
      if permission
        "Not authorized: missing permission '#{permission}'"
      elsif role
        "Not authorized: missing role '#{role}'"
      else
        "Not authorized"
      end
    end
  end
end
