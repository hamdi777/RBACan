module Rbacan
  module ViewHelpers
    # Renders the block only if the current user has the given permission.
    #
    # Usage in views:
    #   <% authorized?(:publish_post) do %>
    #     <%= link_to "Publish", publish_post_path(@post) %>
    #   <% end %>
    def authorized?(permission, &block)
      return unless current_user&.can?(permission.to_s)
      capture(&block) if block_given?
    end
  end
end
