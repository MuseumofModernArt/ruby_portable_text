require "test_helper"

class PortableText::Html::BlockTypes::BlockTest < Minitest::Test
  include Phlex::Testing::ViewHelper

  def setup
    @block_params = {
      _key: "36be0ac1493e",
      _type: "block",
      markDefs: [],
      style: "h1"
    }
  end

  def new_block(**params)
    PortableText::BlockTypes::Block.new(
      **@block_params,
      **params
    )
  end

  def test_delegate_methods_to_block
    block = new_block
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal block.style, html_block.style
    assert_equal block.children, html_block.children
    assert_equal block.mark_defs, html_block.mark_defs
    assert_equal block.list_item, html_block.list_item
  end

  def test_render_creates_a_tag_matching_the_style
    block = new_block
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal "<h1></h1>", render(html_block)
  end

  def test_when_children_creates_a_tag_with_children_as_inside_nodes
    block = new_block(
      children: [
        PortableText::BlockTypes::Span.new(
          _key: "f55398075dd5",
          _type: "span",
          marks: [],
          text: "Title h1"
        )
      ]
    )
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal "<h1>Title h1</h1>", render(html_block)
  end

  def test_when_node_style_unknwon_defaults_to_p
    block = new_block(style: "something")
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal "<p></p>", render(html_block)
  end

  def test_when_node_is_list_item_returns_li
    block = new_block(listItem: true)
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal "<li></li>", render(html_block)
  end

  def test_when_node_configuration_is_overriden_adds_new_node_arguments
    PortableText::Html::Config.config.block.styles[:h1] = { node: :h1, class: "title" }
    block = new_block
    html_block = PortableText::Html::BlockTypes::Block.new(block)
    assert_equal "<h1 class=\"title\"></h1>", render(html_block)

    PortableText::Html::Config.config.block.styles[:h1] = { node: :h1 }
  end

  def test_when_a_node_override_is_given_it_replaces_the_node_derived_from_the_style
    html_block = PortableText::Html::BlockTypes::Block.new(new_block, node_override: { node: :span, class: "title" })
    assert_equal "<span class=\"title\"></span>", render(html_block)
  end

  def test_a_node_override_takes_precedence_over_the_list_item_node
    html_block = PortableText::Html::BlockTypes::Block.new(new_block(listItem: true), node_override: { node: :span })
    assert_equal "<span></span>", render(html_block)
  end

  def test_a_node_override_does_not_leak_into_blocks_built_without_one
    render(PortableText::Html::BlockTypes::Block.new(new_block, node_override: { node: :span }))
    assert_equal "<h1></h1>", render(PortableText::Html::BlockTypes::Block.new(new_block))
  end
end
