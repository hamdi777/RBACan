module Rbacan
  class ConfigurationError < StandardError; end
  class UnsafeLegacyApi < StandardError; end

  class AuthorizationContext
    ATTRIBUTES = %i[tenant property vertical subject at metadata].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(tenant:, property: nil, vertical: nil, subject: nil, at: Time.now, metadata: {})
      raise ArgumentError, 'authorization tenant must identify a tenant' unless identifying_tenant?(tenant)

      @tenant = deep_copy_and_freeze(tenant, label: 'authorization tenant')
      @property = deep_copy_and_freeze(property, label: 'authorization property')
      @vertical = deep_copy_and_freeze(vertical, label: 'authorization vertical')
      @subject = deep_copy_and_freeze(subject, label: 'authorization subject')
      @at = copy_and_freeze_time(at)
      @metadata = deep_copy_and_freeze(metadata, label: 'authorization metadata')
      freeze
    end

    private

    def deep_copy_and_freeze(value, label:)
      copy = case value
             when Hash
               value.to_h do |key, item|
                 [ deep_copy_and_freeze(key, label: label), deep_copy_and_freeze(item, label: label) ]
               end
             when Array
               value.map { |item| deep_copy_and_freeze(item, label: label) }
             when String
               value.dup
             when Integer
               value
             when Float
               raise ArgumentError, "#{label} supports only finite JSON numbers" unless value.finite?

               value
             when NilClass, TrueClass, FalseClass, Symbol
               value
             else
               raise ArgumentError,
                     "#{label} supports only hashes, arrays, strings, numbers, booleans, nil, and symbols"
             end
      copy.freeze
    end

    def copy_and_freeze_time(value)
      time = value.to_time if value.respond_to?(:to_time)
      raise ArgumentError, 'authorization timestamp must be time-like' unless time.is_a?(Time)

      time.dup.freeze
    end

    def identifying_tenant?(value)
      case value
      when String, Array, Hash
        !value.empty?
      when Integer
        true
      when Float
        value.finite?
      when Symbol
        !value.to_s.empty?
      else
        false
      end
    end
  end

  class AuthorizationRequest
    attr_reader :user, :permission, :role, :context

    def initialize(user:, permission:, role:, context:)
      @user = user
      @permission = permission&.to_s&.dup&.freeze
      @role = role&.to_s&.dup&.freeze
      @context = context
      freeze
    end
  end

  class AssignmentRequest
    attr_reader :user, :role, :context

    def initialize(user:, role:, context:)
      @user = user
      @role = role.to_s.dup.freeze
      @context = context
      freeze
    end
  end

  class << self
    def ensure_legacy_mode!(method_name)
      return if legacy_mode

      raise UnsafeLegacyApi,
            "#{method_name} is a legacy unscoped API; set Rbacan.legacy_mode = true to opt in"
    end

    def authorized?(user:, permission: nil, role: nil, context:)
      validate_authorization_target!(permission, role)
      validate_context!(context)
      return false unless user && authorization_adapter

      request = AuthorizationRequest.new(
        user: user,
        permission: permission&.to_s,
        role: role&.to_s,
        context: context
      )

      !!call_authorization_adapter(request)
    end

    def assign_role(user:, role:, context:)
      call_assignment_adapter(:assign, user: user, role: role, context: context)
    end

    def revoke_role(user:, role:, context:)
      call_assignment_adapter(:revoke, user: user, role: role, context: context)
    end

    private

    def validate_authorization_target!(permission, role)
      if permission.nil? ^ role.nil?
        target = permission || role
        raise ArgumentError, 'authorization permission or role cannot be blank' if target.to_s.empty?

        return
      end

      raise ArgumentError, 'Provide exactly one permission or role'
    end

    def validate_context!(context)
      raise ArgumentError, 'authorization context is required' unless context.is_a?(AuthorizationContext)
    end

    def call_authorization_adapter(request)
      if authorization_adapter.respond_to?(:allowed?)
        authorization_adapter.allowed?(request)
      elsif authorization_adapter.respond_to?(:call)
        authorization_adapter.call(request)
      else
        raise ConfigurationError, 'authorization adapter must respond to allowed? or call'
      end
    end

    def call_assignment_adapter(action, user:, role:, context:)
      validate_context!(context)
      raise ArgumentError, 'assignment user is required' unless user
      raise ArgumentError, 'assignment role is required' if role.nil? || role.to_s.empty?
      unless assignment_adapter&.respond_to?(action)
        raise ConfigurationError, "assignment adapter must respond to #{action}"
      end

      request = AssignmentRequest.new(user: user, role: role.to_s, context: context)
      assignment_adapter.public_send(action, request)
    end
  end
end
