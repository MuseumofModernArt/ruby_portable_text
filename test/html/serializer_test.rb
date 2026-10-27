require "test_helper"

class PortableText::Html::SerializerTest < Minitest::Test
  include Phlex::Testing::ViewHelper

  def test_it_renders_blocks_concatenated
    blocks = [
      PortableText::BlockTypes::Block.new(
        _key: "36be0ac1493e",
        _type: "block",
        markDefs: [],
        style: "h1"
      ),
      PortableText::BlockTypes::Image.new(
        _key: "36be0ac1493e",
        _type: "image",
        asset: { "url" => "https://example.com/image.jpg" }
      )
    ]

    serializer = PortableText::Html::Serializer.new(blocks)
    assert_equal "<h1></h1><img src=\"https://example.com/image.jpg\">", render(serializer)
  end

  def test_node_override_replaces_the_node_of_text_blocks_and_leaves_other_blocks_alone
    override = { node: :span, id: "title" }
    serializer = PortableText::Html::Serializer.new(text_and_image_blocks).content(node_override: override)

    assert_equal "<span id=\"title\"></span><img src=\"https://example.com/image.jpg\">", render(serializer)
  end

  def test_node_override_applies_to_custom_block_types_inheriting_from_the_block_type
    custom_block = Class.new(PortableText::Html::BlockTypes::Block)
    with_block_type(:block, custom_block) do
      serializer = PortableText::Html::Serializer.new(text_and_image_blocks).content(node_override: { node: :span })

      assert_equal "<span></span><img src=\"https://example.com/image.jpg\">", render(serializer)
    end
  end

  def test_nodes_are_rendered_from_the_config_again_after_a_render_with_an_override
    render(PortableText::Html::Serializer.new(text_and_image_blocks).content(node_override: { node: :span }))

    assert_equal "<h1></h1><img src=\"https://example.com/image.jpg\">",
                 render(PortableText::Html::Serializer.new(text_and_image_blocks))
  end

  def test_overriding_the_node_does_not_define_new_classes_for_every_render
    blocks = text_and_image_blocks
    render(PortableText::Html::Serializer.new(blocks).content(node_override: { node: :span, id: "warmup" }))
    GC.start
    classes_before = ObjectSpace.each_object(Class).count

    300.times do |i|
      render(PortableText::Html::Serializer.new(blocks).content(node_override: { node: :span, id: "title-#{i}" }))
    end
    GC.start

    assert_operator ObjectSpace.each_object(Class).count - classes_before, :<, 10
  end

  private

  def text_and_image_blocks
    [
      PortableText::BlockTypes::Block.new(_key: "36be0ac1493e", _type: "block", markDefs: [], style: "h1"),
      PortableText::BlockTypes::Image.new(
        _key: "36be0ac1493e",
        _type: "image",
        asset: { "url" => "https://example.com/image.jpg" }
      )
    ]
  end

  def with_block_type(type, klass)
    original = PortableText::Html::Config.config.block.types[type]
    PortableText::Html::Config.config.block.types[type] = klass
    yield
  ensure
    PortableText::Html::Config.config.block.types[type] = original
  end
end
