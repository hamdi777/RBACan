require 'spec_helper'

RSpec.describe 'host-owned authorization' do
  let(:user) { User.create!(name: 'Ada') }
  let(:context) do
    Rbacan::AuthorizationContext.new(
      tenant: 'tenant-1',
      property: 'hotel-1',
      vertical: 'hotel',
      subject: 'reservation-1',
      at: Time.utc(2026, 9, 11, 12, 0, 0),
      metadata: { request_id: 'request-1' }
    )
  end

  before do
    Rbacan.authorization_adapter = nil
    Rbacan.assignment_adapter = nil
    Rbacan.legacy_mode = false
  end

  after do
    Rbacan.authorization_adapter = nil
    Rbacan.assignment_adapter = nil
    Rbacan.legacy_mode = true
  end

  it 'fails closed when no authorization adapter is configured' do
    expect(
      Rbacan.authorized?(user: user, permission: :hotel_reservations_read, context: context)
    ).to be false
  end

  it 'passes the complete authorization request to the host adapter' do
    received = nil
    Rbacan.authorization_adapter = lambda do |request|
      received = request
      request.permission == 'hotel_reservations_read' && request.context.equal?(context)
    end

    expect(
      Rbacan.authorized?(user: user, permission: :hotel_reservations_read, context: context)
    ).to be true
    expect(received.user).to equal(user)
    expect(received.role).to be_nil
    expect(received.context.tenant).to eq('tenant-1')
    expect(received.context.property).to eq('hotel-1')
    expect(received.context.vertical).to eq('hotel')
    expect(received.context.subject).to eq('reservation-1')
    expect(received.context.at).to eq(Time.utc(2026, 9, 11, 12, 0, 0))
  end

  it 'requires exactly one permission or role' do
    expect do
      Rbacan.authorized?(user: user, context: context)
    end.to raise_error(ArgumentError, /exactly one/)

    expect do
      Rbacan.authorized?(user: user, permission: :read, role: :admin, context: context)
    end.to raise_error(ArgumentError, /exactly one/)

    expect do
      Rbacan.authorized?(user: user, permission: '', context: context)
    end.to raise_error(ArgumentError, /blank/)
  end

  it 'requires an explicit authorization context' do
    expect do
      Rbacan.authorized?(user: user, permission: :read, context: nil)
    end.to raise_error(ArgumentError, /context/)
  end

  it 'keeps authorization contexts immutable' do
    expect(context).to be_frozen
    expect(context.metadata).to be_frozen
  end

  it 'copies and deeply freezes every caller-owned context value' do
    tenant = +'tenant-1'
    property = { type: +'Hotel', id: +'hotel-1' }
    vertical = +'hotel'
    subject = { type: +'Reservation', id: +'reservation-1' }
    at = Time.utc(2026, 9, 11, 12, 0, 0)

    immutable_context = Rbacan::AuthorizationContext.new(
      tenant: tenant,
      property: property,
      vertical: vertical,
      subject: subject,
      at: at
    )

    tenant.replace('tenant-2')
    property[:id].replace('hotel-2')
    vertical.replace('condominium')
    subject[:id].replace('reservation-2')
    at.instance_variable_set(:@caller_mutation, true)

    expect(immutable_context.tenant).to eq('tenant-1')
    expect(immutable_context.property).to eq(type: 'Hotel', id: 'hotel-1')
    expect(immutable_context.vertical).to eq('hotel')
    expect(immutable_context.subject).to eq(type: 'Reservation', id: 'reservation-1')
    expect(immutable_context.at).to eq(Time.utc(2026, 9, 11, 12, 0, 0))
    expect(immutable_context.at.instance_variable_defined?(:@caller_mutation)).to be false
    expect(immutable_context.tenant).to be_frozen
    expect(immutable_context.property).to be_frozen
    expect(immutable_context.property[:id]).to be_frozen
    expect(immutable_context.vertical).to be_frozen
    expect(immutable_context.subject).to be_frozen
    expect(immutable_context.subject[:id]).to be_frozen
    expect(immutable_context.at).to be_frozen
  end

  it 'rejects a missing or non-identifying tenant before adapter dispatch' do
    Rbacan.authorization_adapter = ->(_request) { raise 'must not be called' }

    [ nil, false, true, '', [], {} ].each do |invalid_tenant|
      expect do
        Rbacan::AuthorizationContext.new(tenant: invalid_tenant)
      end.to raise_error(ArgumentError, /tenant/)
    end
  end

  it 'rejects mutable numeric subclasses in context values' do
    mutable_numeric_class = Class.new(Numeric) do
      attr_accessor :label
    end
    mutable_numeric = mutable_numeric_class.new
    mutable_numeric.label = +'tenant-1'

    expect do
      Rbacan::AuthorizationContext.new(tenant: mutable_numeric)
    end.to raise_error(ArgumentError, /tenant/)
  end

  it 'rejects unsupported mutable authorization metadata' do
    expect do
      Rbacan::AuthorizationContext.new(tenant: 'tenant-1', metadata: { object: Object.new })
    end.to raise_error(ArgumentError, /metadata/)
  end

  it 'copies and deeply freezes authorization metadata' do
    metadata = { audit: { request_ids: [ +'request-1' ] } }
    immutable_context = Rbacan::AuthorizationContext.new(tenant: 'tenant-1', metadata: metadata)

    metadata[:audit][:request_ids] << 'caller-mutation'

    expect(immutable_context.metadata).to eq(audit: { request_ids: [ 'request-1' ] })
    expect { immutable_context.metadata[:audit][:request_ids] << 'adapter-mutation' }
      .to raise_error(FrozenError)
  end

  it 'copies and freezes authorization target codes' do
    permission = +'hotel.reservations.read'
    received = nil
    Rbacan.authorization_adapter = ->(request) { received = request }

    Rbacan.authorized?(user: user, permission: permission, context: context)
    permission.replace('hotel.settings.manage')

    expect(received.permission).to eq('hotel.reservations.read')
    expect(received.permission).to be_frozen
  end

  it 'delegates assignment and revocation without deleting host records' do
    calls = []
    Rbacan.assignment_adapter = Object.new.tap do |adapter|
      adapter.define_singleton_method(:assign) { |request| calls << [:assign, request] }
      adapter.define_singleton_method(:revoke) { |request| calls << [:revoke, request] }
    end

    Rbacan.assign_role(user: user, role: :hotel_gm, context: context)
    Rbacan.revoke_role(user: user, role: :hotel_gm, context: context)

    expect(calls.map(&:first)).to eq(%i[assign revoke])
    expect(calls.map { |(_, request)| request.role }).to eq(%w[hotel_gm hotel_gm])
    expect(calls.map { |(_, request)| request.context }).to all(equal(context))
  end

  it 'fails closed when no assignment adapter is configured' do
    expect do
      Rbacan.assign_role(user: user, role: :hotel_gm, context: context)
    end.to raise_error(Rbacan::ConfigurationError, /assignment adapter/)
  end

  it 'rejects incomplete assignments before calling the host adapter' do
    Rbacan.assignment_adapter = Object.new.tap do |adapter|
      adapter.define_singleton_method(:assign) { raise 'must not be called' }
      adapter.define_singleton_method(:revoke) { raise 'must not be called' }
    end

    expect { Rbacan.assign_role(user: nil, role: :hotel_gm, context: context) }
      .to raise_error(ArgumentError, /user/)
    expect { Rbacan.assign_role(user: user, role: nil, context: context) }
      .to raise_error(ArgumentError, /role/)
  end

  it 'provides an association-free concern for host user models' do
    host_class = Class.new do
      include Rbacan::Authorizable
    end
    host_user = host_class.new
    Rbacan.authorization_adapter = ->(request) { request.user.equal?(host_user) }

    expect(host_user.can?(:hotel_reservations_read, context: context)).to be true
    expect(host_user.has_role?(:hotel_gm, context: context)).to be true
    expect(host_class).not_to respond_to(:has_many)
  end

  it 'authorizes controllers through the host context instead of a Rails session convention' do
    Rbacan.authorization_adapter = lambda do |request|
      request.user.equal?(user) &&
        request.permission == 'hotel_reservations_read' &&
        request.context.equal?(context)
    end

    controller_class = Class.new do
      include Rbacan::Authorization

      attr_reader :current_user

      def initialize(current_user, context)
        @current_user = current_user
        @context = context
      end

      private

      def rbacan_authorization_context
        @context
      end
    end

    controller = controller_class.new(user, context)
    expect { controller.authorize!(:hotel_reservations_read) }.not_to raise_error
    expect { controller.authorize!(:hotel_settings_manage) }
      .to raise_error(Rbacan::NotAuthorized) { |error|
        expect(error.code).to eq('rbacan.not_authorized.permission')
      }
  end

  it 'rejects controller authorization when the host omits context' do
    controller_class = Class.new do
      include Rbacan::Authorization
      attr_reader :current_user

      def initialize(current_user)
        @current_user = current_user
      end
    end

    expect { controller_class.new(user).authorize!(:hotel_reservations_read) }
      .to raise_error(Rbacan::ConfigurationError, /authorization context/)
  end

  it 'blocks destructive and unscoped legacy APIs unless the host opts in' do
    expect { user.assign_role(:admin) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.remove_role(:admin) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.can?(:edit_post) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.can_in_tenant?(:edit_post, 'tenant-1') }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.has_role?(:admin) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.has_role_in_tenant?(:admin, 'tenant-1') }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.has_any_role?(:admin, :viewer) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.can_all?(:edit_post, :delete_post) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { user.roles_for_tenant('tenant-1') }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { User.with_role(:admin) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
    expect { User.with_permission(:edit_post) }
      .to raise_error(Rbacan::UnsafeLegacyApi, /legacy_mode/)
  end

  it 'uses configured key columns throughout explicitly enabled legacy APIs' do
    previous_role_key = Rbacan.role_key
    previous_permission_key = Rbacan.permission_key
    Rbacan.legacy_mode = true
    Rbacan.role_key = :code
    Rbacan.permission_key = :code

    role = Rbacan::Role.create!(name: 'legacy-role-row', code: 'hotel.gm')
    permission = Rbacan::Permission.create!(
      name: 'legacy-permission-row',
      code: 'hotel.settings.manage'
    )
    Rbacan::RolePermission.create!(role: role, permission: permission)

    user.assign_role('hotel.gm')

    expect(user.has_role?('hotel.gm')).to be true
    expect(user.can?('hotel.settings.manage')).to be true
    expect(User.with_role('hotel.gm')).to include(user)
    expect(User.with_permission('hotel.settings.manage')).to include(user)
  ensure
    Rbacan.role_key = previous_role_key
    Rbacan.permission_key = previous_permission_key
    Rbacan.legacy_mode = false
  end

  it 'supports host role and permission key columns' do
    coded_role_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'coded_roles'
    end
    coded_permission_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'coded_permissions'
    end
    stub_const('CodedRole', coded_role_class)
    stub_const('CodedPermission', coded_permission_class)

    previous = {
      role_class: Rbacan.role_class,
      permission_class: Rbacan.permission_class,
      role_key: Rbacan.role_key,
      permission_key: Rbacan.permission_key
    }
    Rbacan.role_class = 'CodedRole'
    Rbacan.permission_class = 'CodedPermission'
    Rbacan.role_key = :code
    Rbacan.permission_key = :code

    expect(Rbacan.create_role(:hotel_gm).code).to eq('hotel_gm')
    expect(Rbacan.create_permission(:hotel_settings_manage).code)
      .to eq('hotel_settings_manage')
    Rbacan::RolesAndPermissions.create_roles([:hotel_front_desk])
    Rbacan::RolesAndPermissions.create_permissions([:hotel_reservations_read])
    expect(coded_role_class.find_by!(code: 'hotel_front_desk')).to be_present
    expect(coded_permission_class.find_by!(code: 'hotel_reservations_read')).to be_present
  ensure
    previous&.each { |setting, value| Rbacan.public_send("#{setting}=", value) }
  end

  it 'authorizes view blocks with the host context' do
    Rbacan.authorization_adapter = ->(request) do
      request.permission == 'hotel_reservations_read' && request.context.equal?(context)
    end
    view_class = Class.new do
      include Rbacan::ViewHelpers

      def initialize(user, context)
        @user = user
        @context = context
      end

      def current_user
        @user
      end

      def rbacan_authorization_context
        @context
      end

      def capture
        yield
      end
    end

    result = view_class.new(user, context).authorized?(:hotel_reservations_read) { 'visible' }
    expect(result).to eq('visible')
  end

  it 'does not shadow the ActionView authorization helper from controllers' do
    registered_helpers = []
    controller_class = Class.new do
      define_singleton_method(:helper_method) { |*names| registered_helpers.concat(names) }
      include Rbacan::Authorization
    end

    expect(controller_class).to be
    expect(registered_helpers).not_to include(:authorized?)
  end

  it 'localizes hardened redirect denials through the stable denial code' do
    Rbacan.unauthorized_handler = :redirect
    Rbacan.authorization_adapter = ->(_request) { false }
    allow(I18n).to receive(:t)
      .with(
        'rbacan.not_authorized.permission',
        permission: 'hotel.reservations.read',
        role: nil,
        raise: true
      )
      .and_return('Permesso negato')

    controller_class = Class.new do
      include Rbacan::Authorization

      attr_reader :redirect

      def current_user
        Object.new
      end

      def rbacan_authorization_context
        @rbacan_authorization_context
      end

      def redirect_to(path, alert:)
        @redirect = [ path, alert ]
      end
    end
    controller = controller_class.new
    controller.instance_variable_set(:@rbacan_authorization_context, context)

    controller.authorize!('hotel.reservations.read')

    expect(controller.redirect).to eq([ '/', 'Permesso negato' ])
  ensure
    Rbacan.unauthorized_handler = :raise
  end

  it 'authorizes route constraints through explicit host resolvers' do
    Rbacan.authorization_adapter = ->(request) do
      request.user.equal?(user) && request.context.equal?(context)
    end
    request = Object.new
    constraint = Rbacan::RouteConstraint.new(
      permission: :hotel_reservations_read,
      user_resolver: ->(source) { user if source.equal?(request) },
      context_resolver: ->(source) { context if source.equal?(request) }
    )

    expect(constraint.matches?(request)).to be true
  end

  it 'fails route constraints closed without host resolvers in hardened mode' do
    request = Struct.new(:env, :session).new({}, {})

    expect(Rbacan::RouteConstraint.new(permission: :read).matches?(request)).to be false
  end

  it 'keeps the generated initializer hardened by default' do
    template = File.read(
      File.expand_path('../lib/generators/install/templates/rbacan.rb', __dir__)
    )
    active_lines = template.lines.reject { |line| line.lstrip.start_with?('#') }.join

    expect(active_lines).not_to match(/config\.legacy_mode\s*=\s*true/)
  end
end
