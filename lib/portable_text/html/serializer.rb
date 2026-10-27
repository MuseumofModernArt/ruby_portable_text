module PortableText
  module Html
    class Serializer < Html::BaseComponent
      include Configured

      param :blocks

      def content(node_override: nil, **_options)
        @node_override = node_override
        self
      end

      def view_template
        @blocks.each do |block|
          render build_block(block)
        end
      end

      private

      def build_block(block)
        block_class = block_type(block.type)
        return block_class.new(block) unless @node_override && block_class <= BlockTypes::Block

        block_class.new(block, node_override: @node_override)
      end
    end
  end
end
