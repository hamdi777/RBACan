RSpec.describe Rbacan do
  it "has a version number" do
    expect(Rbacan::VERSION).to eq("0.2.0")
  end
end

RSpec.describe Rbacan::Permittable do
  let!(:admin_role)  { Rbacan::Role.create!(name: "admin") }
  let!(:mod_role)    { Rbacan::Role.create!(name: "moderator") }
  let!(:edit_perm)   { Rbacan::Permission.create!(name: "edit_post") }
  let!(:delete_perm) { Rbacan::Permission.create!(name: "delete_post") }
  let!(:user)        { User.create!(name: "Alice") }

  before do
    Rbacan::RolePermission.create!(role_id: admin_role.id, permission_id: edit_perm.id)
    Rbacan::RolePermission.create!(role_id: admin_role.id, permission_id: delete_perm.id)
    Rbacan::RolePermission.create!(role_id: mod_role.id,   permission_id: edit_perm.id)
  end

  describe "#assign_role" do
    it "assigns a role to the user" do
      user.assign_role("admin")
      expect(user.roles.pluck(:name)).to include("admin")
    end

    it "is idempotent — calling twice does not create a duplicate UserRole" do
      user.assign_role("admin")
      user.assign_role("admin")
      expect(user.user_roles.where(role_id: admin_role.id).count).to eq(1)
    end

    it "raises ArgumentError for a non-existent role" do
      expect { user.assign_role("ghost") }.to raise_error(ArgumentError, /not found/)
    end

    it "persists the UserRole record in the database" do
      user.assign_role("admin")
      expect(Rbacan::UserRole.where(user_id: user.id, role_id: admin_role.id)).to exist
    end
  end

  describe "#remove_role" do
    before { user.assign_role("admin") }

    it "removes the role from the user" do
      user.remove_role("admin")
      expect(user.roles.pluck(:name)).not_to include("admin")
    end

    it "does not raise when the user does not have the role" do
      expect { user.remove_role("moderator") }.not_to raise_error
    end

    it "does not remove other roles" do
      user.assign_role("moderator")
      user.remove_role("admin")
      expect(user.roles.pluck(:name)).to include("moderator")
    end
  end

  describe "#can?" do
    before { user.assign_role("admin") }

    it "returns true when the user has the permission via a role" do
      expect(user.can?("edit_post")).to be true
    end

    it "accepts a symbol argument" do
      expect(user.can?(:delete_post)).to be true
    end

    it "returns false when the user does not have the permission" do
      expect(user.can?("fly")).to be false
    end

    it "returns false when the user has no roles" do
      expect(User.create!(name: "Bob").can?("edit_post")).to be false
    end

    it "issues exactly one SQL query" do
      query_count = 0
      counter = ->(*) { query_count += 1 }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        user.can?("edit_post")
      end
      expect(query_count).to eq(1)
    end
  end

  describe "#has_role?" do
    before { user.assign_role("admin") }

    it "returns true when the user has the role" do
      expect(user.has_role?(:admin)).to be true
    end

    it "returns false when the user does not have the role" do
      expect(user.has_role?(:moderator)).to be false
    end
  end

  describe "#has_any_role?" do
    before { user.assign_role("admin") }

    it "returns true when the user has at least one of the listed roles" do
      expect(user.has_any_role?(:admin, :moderator)).to be true
    end

    it "returns false when the user has none of the listed roles" do
      expect(user.has_any_role?(:moderator, :viewer)).to be false
    end
  end

  describe "#can_all?" do
    before { user.assign_role("admin") }

    it "returns true when the user has all listed permissions" do
      expect(user.can_all?(:edit_post, :delete_post)).to be true
    end

    it "returns false when the user is missing at least one permission" do
      expect(user.can_all?(:edit_post, :fly)).to be false
    end
  end

  describe ".with_role" do
    let!(:other_user) { User.create!(name: "Charlie") }

    before do
      user.assign_role("admin")
      other_user.assign_role("moderator")
    end

    it "returns only users with the specified role" do
      result = User.with_role(:admin)
      expect(result).to include(user)
      expect(result).not_to include(other_user)
    end
  end

  describe ".with_permission" do
    let!(:mod_user) { User.create!(name: "Dave") }

    before do
      user.assign_role("admin")         # has edit_post + delete_post
      mod_user.assign_role("moderator") # has edit_post only
    end

    it "returns users that have the permission via any role" do
      result = User.with_permission(:edit_post)
      expect(result).to include(user, mod_user)
    end

    it "does not include users lacking the permission" do
      result = User.with_permission(:delete_post)
      expect(result).to include(user)
      expect(result).not_to include(mod_user)
    end
  end
end

RSpec.describe Rbacan::Authorization do
  let!(:admin_role) { Rbacan::Role.create!(name: "admin") }
  let!(:edit_perm)  { Rbacan::Permission.create!(name: "edit_post") }
  let!(:user)       { User.create!(name: "Eve") }

  before do
    Rbacan::RolePermission.create!(role_id: admin_role.id, permission_id: edit_perm.id)
    user.assign_role("admin")
  end

  let(:controller_class) do
    Class.new do
      include Rbacan::Authorization
      attr_accessor :current_user

      def initialize(user)
        @current_user = user
      end

      def redirect_to(path, options = {})
        @redirected_to      = path
        @redirect_options   = options
      end

      attr_reader :redirected_to, :redirect_options
    end
  end

  describe "#authorize!" do
    context "when unauthorized_handler is :raise (default)" do
      it "does not raise when the user has the permission" do
        ctrl = controller_class.new(user)
        expect { ctrl.authorize!(:edit_post) }.not_to raise_error
      end

      it "raises Rbacan::NotAuthorized when the user lacks the permission" do
        ctrl = controller_class.new(user)
        expect { ctrl.authorize!(:delete_post) }
          .to raise_error(Rbacan::NotAuthorized, /delete_post/)
      end

      it "raises Rbacan::NotAuthorized when there is no current_user" do
        ctrl = controller_class.new(nil)
        expect { ctrl.authorize!(:edit_post) }.to raise_error(Rbacan::NotAuthorized)
      end
    end

    context "when unauthorized_handler is :redirect" do
      around do |example|
        original = Rbacan.unauthorized_handler
        Rbacan.unauthorized_handler      = :redirect
        Rbacan.unauthorized_redirect_path = "/login"
        example.run
        Rbacan.unauthorized_handler = original
      end

      it "redirects instead of raising" do
        ctrl = controller_class.new(user)
        ctrl.authorize!(:fly)
        expect(ctrl.redirected_to).to eq("/login")
      end
    end

    context "when unauthorized_handler is a lambda" do
      around do |example|
        original = Rbacan.unauthorized_handler
        Rbacan.unauthorized_handler = ->(c, **) { c.instance_variable_set(:@custom_handled, true) }
        example.run
        Rbacan.unauthorized_handler = original
      end

      it "calls the lambda" do
        ctrl = controller_class.new(user)
        ctrl.authorize!(:fly)
        expect(ctrl.instance_variable_get(:@custom_handled)).to be true
      end
    end
  end

  describe "#authorize_role!" do
    it "does not raise when the user has the role" do
      ctrl = controller_class.new(user)
      expect { ctrl.authorize_role!(:admin) }.not_to raise_error
    end

    it "raises Rbacan::NotAuthorized when the user lacks the role" do
      ctrl = controller_class.new(user)
      expect { ctrl.authorize_role!(:superadmin) }
        .to raise_error(Rbacan::NotAuthorized, /superadmin/)
    end
  end
end
