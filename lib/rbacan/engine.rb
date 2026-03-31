module Rbacan
  require "rails/all"
  class Engine < ::Rails::Engine
    engine_name 'rbacan'

    initializer "rbacan.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include Rbacan::ViewHelpers
      end
    end
  end
end
