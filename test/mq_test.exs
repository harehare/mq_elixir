defmodule MqTest do
  use ExUnit.Case, async: true
  doctest Mq

  alias Mq.{Filter, Query}

  describe "run/3" do
    test "extracts h1 headings" do
      content = "# Hello World\n\n## Heading2\n\nText"
      assert {:ok, result} = Mq.run(".h1", content)
      assert result.values == ["# Hello World"]
      assert result.text == "# Hello World"
    end

    test "extracts h2 headings" do
      content = "# Hello World\n\n## Heading2\n\nText"
      assert {:ok, result} = Mq.run(".h2", content)
      assert result.values == ["## Heading2"]
    end

    test "extracts multiple h2 headings" do
      content = "# Main Title\n\n## Heading2A\n\nText\n\n## Heading2B\n\nMore text"
      assert {:ok, result} = Mq.run(".h2", content)
      assert result.values == ["## Heading2A", "## Heading2B"]
    end

    test "filters headings with select" do
      content = "# Product\n\n## Features\n\nText\n\n## Installation\n\nMore text"
      assert {:ok, result} = Mq.run(".h2 | select(contains(\"Feature\"))", content)
      assert result.values == ["## Features"]
    end

    test "extracts list items" do
      content = "# List\n\n- Item 1\n- Item 2\n- Item 3"
      assert {:ok, result} = Mq.run(".[]", content)
      assert result.values == ["- Item 1", "- Item 2", "- Item 3"]
    end

    test "extracts code blocks" do
      content = "# Code\n\n```python\nprint('Hello')\n```"
      assert {:ok, result} = Mq.run(".code", content)
      assert result.values == ["```python\nprint('Hello')\n```"]
    end
  end

  describe "run/3 with different input formats" do
    test "processes TEXT format" do
      options = %Mq.Options{input_format: :text}
      content = "Line 1\nLine 2\nLine 3"
      assert {:ok, result} = Mq.run("select(contains(\"2\"))", content, options)
      assert result.values == ["Line 2"]
    end

    test "processes MDX format" do
      options = %Mq.Options{input_format: :mdx}
      content = "# MDX Content\n\n<Component />"
      assert {:ok, result} = Mq.run("select(is_mdx())", content, options)
      assert result.values == ["<Component />"]
    end

    test "processes HTML format" do
      options = %Mq.Options{input_format: :html}
      content = "<h1>Hello</h1><p>World</p>"
      assert {:ok, result} = Mq.run("select(contains(\"Hello\"))", content, options)
      assert result.values == ["# Hello"]
    end
  end

  describe "run/3 with invalid queries" do
    test "returns error for invalid syntax" do
      assert {:error, reason} = Mq.run(".invalid_selector!!!", "# Heading")
      assert reason =~ "Error evaluating query"
    end
  end

  describe "html_to_markdown/2" do
    test "converts HTML to Markdown" do
      html_content = "<h1>Hello World</h1><p>This is a <strong>test</strong>.</p>"
      expected_markdown = "# Hello World\n\nThis is a **test**."
      assert {:ok, markdown} = Mq.html_to_markdown(html_content)
      assert String.trim(markdown) == expected_markdown
    end

    test "converts HTML with options" do
      html_content =
        "<html><head><title>Page Title</title></head><body><h1>Content</h1></body></html>"

      options = %Mq.ConversionOptions{use_title_as_h1: true}

      assert {:ok, markdown} = Mq.html_to_markdown(html_content, options)
      assert markdown =~ "# Page Title"
    end

    test "handles empty HTML" do
      assert {:ok, markdown} = Mq.html_to_markdown("")
      assert markdown == ""
    end
  end

  describe "Mq.Result" do
    test "implements Enumerable protocol" do
      {:ok, result} = Mq.run(".h", "# H1\n## H2\n### H3")

      assert Enum.count(result) == 3
      assert Enum.member?(result, "# H1")
      assert Enum.at(result, 0) == "# H1"
    end

    test "implements String.Chars protocol" do
      {:ok, result} = Mq.run(".h1", "# Title")
      assert to_string(result) == "# Title"
    end

    test "length/1 returns correct count" do
      {:ok, result} = Mq.run(".h", "# H1\n## H2")
      assert Mq.Result.length(result) == 2
    end

    test "empty?/1 checks for empty results" do
      {:ok, result} = Mq.run(".h1", "No headings here")
      assert Mq.Result.empty?(result)
    end
  end

  describe "Mq.Options" do
    test "to_map/1 converts struct to map" do
      options = %Mq.Options{input_format: :markdown}
      map = Mq.Options.to_map(options)

      assert map == %{input_format: :markdown}
    end

    test "to_map/1 removes nil values" do
      options = %Mq.Options{input_format: :markdown}
      map = Mq.Options.to_map(options)

      refute Map.has_key?(map, :list_style)
    end
  end

  describe "Mq.InputFormat" do
    test "all/0 returns all formats" do
      formats = Mq.InputFormat.all()
      assert :markdown in formats
      assert :mdx in formats
      assert length(formats) == 6
    end

    test "valid?/1 validates formats" do
      assert Mq.InputFormat.valid?(:markdown)
      refute Mq.InputFormat.valid?(:invalid)
    end
  end

  describe "Mq.Query selectors" do
    test "h1 through h6" do
      for n <- 1..6 do
        assert to_string(apply(Query, :"h#{n}", [])) == ".h#{n}"
      end
    end

    test "block element selectors" do
      assert to_string(Query.heading()) == ".heading"
      assert to_string(Query.code()) == ".code"
      assert to_string(Query.paragraph()) == ".p"
      assert to_string(Query.blockquote()) == ".blockquote"
      assert to_string(Query.image()) == ".image"
      assert to_string(Query.link()) == ".link"
      assert to_string(Query.text()) == ".text"
      assert to_string(Query.strong()) == ".strong"
      assert to_string(Query.emphasis()) == ".emphasis"
      assert to_string(Query.delete()) == ".delete"
      assert to_string(Query.math()) == ".math"
      assert to_string(Query.table()) == ".table"
      assert to_string(Query.table_align()) == ".table_align"
      assert to_string(Query.html()) == ".html"
      assert to_string(Query.definition()) == ".definition"
      assert to_string(Query.footnote()) == ".footnote"
      assert to_string(Query.toml()) == ".toml"
      assert to_string(Query.yaml()) == ".yaml"
    end

    test "inline element selectors" do
      assert to_string(Query.code_inline()) == ".code_inline"
      assert to_string(Query.math_inline()) == ".math_inline"
      assert to_string(Query.link_ref()) == ".link_ref"
      assert to_string(Query.image_ref()) == ".image_ref"
      assert to_string(Query.footnote_ref()) == ".footnote_ref"
      assert to_string(Query.line_break()) == ".break"
    end

    test "task list selectors" do
      assert to_string(Query.task()) == ".task"
      assert to_string(Query.todo()) == ".todo"
      assert to_string(Query.done()) == ".done"
    end

    test "list and table selectors" do
      assert to_string(Query.list()) == ".[]"
      assert to_string(Query.list_at(0)) == ".[0]"
      assert to_string(Query.list_at(2)) == ".[2]"
      assert to_string(Query.table_row(0)) == ".[0][]"
      assert to_string(Query.table_col(1)) == ".[][1]"
      assert to_string(Query.table_cell(1, 2)) == ".[1][2]"
    end

    test "mdx selectors" do
      assert to_string(Query.mdx_jsx_flow_element()) == ".mdx_jsx_flow_element"
      assert to_string(Query.mdx_text_expression()) == ".mdx_text_expression"
      assert to_string(Query.mdx_jsx_text_element()) == ".mdx_jsx_text_element"
      assert to_string(Query.mdx_flow_expression()) == ".mdx_flow_expression"
      assert to_string(Query.mdx_js_esm()) == ".mdx_js_esm"
    end

    test "recursive selector" do
      assert to_string(Query.recursive()) == ".."
    end

    test "standalone attribute selectors" do
      assert to_string(Query.value()) == ".value"
      assert to_string(Query.lang()) == ".lang"
      assert to_string(Query.meta()) == ".meta"
      assert to_string(Query.fence()) == ".fence"
      assert to_string(Query.url()) == ".url"
      assert to_string(Query.alt()) == ".alt"
      assert to_string(Query.depth()) == ".depth"
      assert to_string(Query.level()) == ".level"
      assert to_string(Query.ordered()) == ".ordered"
      assert to_string(Query.checked()) == ".checked"
      assert to_string(Query.column()) == ".column"
      assert to_string(Query.row()) == ".row"
      assert to_string(Query.align()) == ".align"
    end

    test "property/1 selector" do
      assert to_string(Query.property("title")) == ".\"title\""
    end
  end

  describe "Mq.Query chaining" do
    test "select with Filter" do
      result = Query.h2() |> Query.select(Filter.contains("Feature")) |> to_string()
      assert result == ".h2 | select(contains(\"Feature\"))"
    end

    test "select with string filter" do
      result = Query.h2() |> Query.select("contains(\"Feature\")") |> to_string()
      assert result == ".h2 | select(contains(\"Feature\"))"
    end

    test "standalone select (no leading selector)" do
      assert to_string(Query.select(Filter.mdx?())) == "select(is_mdx())"
    end

    test "output conversions" do
      assert to_string(Query.h2() |> Query.to_text()) == ".h2 | to_text()"
      assert to_string(Query.h2() |> Query.to_markdown()) == ".h2 | to_markdown()"
      assert to_string(Query.text() |> Query.to_mdx()) == ".text | to_mdx()"
      assert to_string(Query.text() |> Query.to_html()) == ".text | to_html()"
      assert to_string(Query.text() |> Query.stringify()) == ".text | to_string()"
      assert to_string(Query.text() |> Query.to_number()) == ".text | to_number()"
      assert to_string(Query.text() |> Query.to_array()) == ".text | to_array()"

      assert to_string(Query.text() |> Query.to_markdown_string()) ==
               ".text | to_markdown_string()"

      assert to_string(Query.text() |> Query.to_boolean()) == ".text | to_boolean()"
    end

    test "chained attribute selectors" do
      assert to_string(Query.link() |> Query.url()) == ".link | .url"
      assert to_string(Query.code() |> Query.lang()) == ".code | .lang"
      assert to_string(Query.code() |> Query.meta()) == ".code | .meta"
      assert to_string(Query.code() |> Query.fence()) == ".code | .fence"
      assert to_string(Query.image() |> Query.alt()) == ".image | .alt"
      assert to_string(Query.link() |> Query.title()) == ".link | .title"
      assert to_string(Query.link_ref() |> Query.ident()) == ".link_ref | .ident"
      assert to_string(Query.link_ref() |> Query.label()) == ".link_ref | .label"
      assert to_string(Query.heading() |> Query.depth()) == ".heading | .depth"
      assert to_string(Query.heading() |> Query.level()) == ".heading | .level"
      assert to_string(Query.list() |> Query.item_index()) == ".[] | .index"
      assert to_string(Query.list() |> Query.ordered()) == ".[] | .ordered"
      assert to_string(Query.task() |> Query.checked()) == ".task | .checked"
      assert to_string(Query.table() |> Query.column()) == ".table | .column"
      assert to_string(Query.table() |> Query.row()) == ".table | .row"
      assert to_string(Query.table_align() |> Query.align()) == ".table_align | .align"

      assert to_string(Query.mdx_jsx_flow_element() |> Query.mdx_name()) ==
               ".mdx_jsx_flow_element | .name"
    end

    test "property/2 chained" do
      assert to_string(Query.text() |> Query.property("title")) == ".text | .\"title\""
    end

    test "string transformations" do
      assert to_string(Query.text() |> Query.trim()) == ".text | trim()"
      assert to_string(Query.text() |> Query.ltrim()) == ".text | ltrim()"
      assert to_string(Query.text() |> Query.rtrim()) == ".text | rtrim()"
      assert to_string(Query.text() |> Query.downcase()) == ".text | downcase()"
      assert to_string(Query.text() |> Query.ascii_downcase()) == ".text | ascii_downcase()"
      assert to_string(Query.text() |> Query.upcase()) == ".text | upcase()"
      assert to_string(Query.text() |> Query.ascii_upcase()) == ".text | ascii_upcase()"
      assert to_string(Query.text() |> Query.len()) == ".text | len()"
      assert to_string(Query.text() |> Query.utf8bytelen()) == ".text | utf8bytelen()"

      assert to_string(Query.text() |> Query.gsub("foo", "bar")) ==
               ".text | gsub(\"foo\", \"bar\")"

      assert to_string(Query.text() |> Query.replace("old", "new")) ==
               ".text | replace(\"old\", \"new\")"

      assert to_string(Query.text() |> Query.split(",")) == ".text | split(\",\")"
      assert to_string(Query.text() |> Query.repeat(3)) == ".text | repeat(3)"
      assert to_string(Query.text() |> Query.slice(0, 5)) == ".text | slice(0, 5)"
      assert to_string(Query.text() |> Query.index("foo")) == ".text | index(\"foo\")"
      assert to_string(Query.text() |> Query.rindex("foo")) == ".text | rindex(\"foo\")"
      assert to_string(Query.text() |> Query.url_decode()) == ".text | url_decode()"

      assert to_string(Query.text() |> Query.capture("(?P<w>\\w+)")) ==
               ".text | capture(\"(?P<w>\\\\w+)\")"

      assert to_string(Query.text() |> Query.scan("\\w+")) == ".text | scan(\"\\\\w+\")"
    end

    test "collection operations" do
      assert to_string(Query.list() |> Query.length()) == ".[] | len()"
      assert to_string(Query.list() |> Query.add("x")) == ".[] | add(\"x\")"
      assert to_string(Query.list() |> Query.first()) == ".[] | first"
      assert to_string(Query.list() |> Query.last()) == ".[] | last"
      assert to_string(Query.list() |> Query.empty()) == ".[] | is_empty()"
      assert to_string(Query.list() |> Query.reverse()) == ".[] | reverse"
      assert to_string(Query.list() |> Query.sort()) == ".[] | sort"
      assert to_string(Query.list() |> Query.compact()) == ".[] | compact"
      assert to_string(Query.list() |> Query.uniq()) == ".[] | uniq"
      assert to_string(Query.list() |> Query.flatten()) == ".[] | flatten"
      assert to_string(Query.list() |> Query.keys()) == ".[] | keys"
      assert to_string(Query.list() |> Query.values()) == ".[] | values"
      assert to_string(Query.list() |> Query.entries()) == ".[] | entries"
      assert to_string(Query.list() |> Query.children()) == ".[] | .children"
      assert to_string(Query.h2() |> Query.nth(2)) == ".h2 | get(2)"
      assert to_string(Query.h2() |> Query.limit(5)) == ".h2 | take(5)"
      assert to_string(Query.h2() |> Query.range(3)) == ".h2 | range(3)"
      assert to_string(Query.list() |> Query.join(", ")) == ".[] | join(\", \")"
      assert to_string(Query.list() |> Query.del("item")) == ".[] | del(\"item\")"
      assert to_string(Query.list() |> Query.insert(0, "new")) == ".[] | insert(0, \"new\")"
    end

    test "type-check filters (mq 0.6.4)" do
      assert to_string(Query.list() |> Query.strings()) == ".[] | strings()"
      assert to_string(Query.list() |> Query.dicts()) == ".[] | dicts()"
      assert to_string(Query.list() |> Query.nones()) == ".[] | nones()"
      assert to_string(Query.list() |> Query.bytes()) == ".[] | bytes()"
      assert to_string(Query.list() |> Query.iterables()) == ".[] | iterables()"
      assert to_string(Query.list() |> Query.scalars()) == ".[] | scalars()"
    end

    test "dict entry helpers (mq 0.6.4)" do
      assert to_string(Query.text() |> Query.has("key")) == ".text | has(\"key\")"
      assert to_string(Query.text() |> Query.from_entries()) == ".text | from_entries()"

      assert to_string(Query.text() |> Query.with_entries("fn(e): e;")) ==
               ".text | with_entries(fn(e): e;)"

      assert to_string(Query.text() |> Query.with_entries(Filter.eq(1))) ==
               ".text | with_entries(eq(1))"

      assert to_string(Query.text() |> Query.walk("fn(x): upcase(x);")) ==
               ".text | walk(fn(x): upcase(x);)"
    end

    test "random / uuid generation (mq 0.6.4)" do
      assert to_string(Query.uuid()) == "uuid()"
      assert to_string(Query.text() |> Query.uuid()) == ".text | uuid()"
      assert to_string(Query.uuid_v4()) == "uuid_v4()"
      assert to_string(Query.text() |> Query.uuid_v4()) == ".text | uuid_v4()"
      assert to_string(Query.uuid_v7()) == "uuid_v7()"
      assert to_string(Query.text() |> Query.uuid_v7()) == ".text | uuid_v7()"
      assert to_string(Query.rand()) == "rand()"
      assert to_string(Query.text() |> Query.rand()) == ".text | rand()"
      assert to_string(Query.rand_int(1, 10)) == "rand_int(1, 10)"
      assert to_string(Query.text() |> Query.rand_int(1, 10)) == ".text | rand_int(1, 10)"
      assert to_string(Query.list() |> Query.shuffle()) == ".[] | shuffle()"
      assert to_string(Query.list() |> Query.sample(2)) == ".[] | sample(2)"
    end

    test "math operations" do
      assert to_string(Query.text() |> Query.abs()) == ".text | abs()"
      assert to_string(Query.text() |> Query.ceil()) == ".text | ceil()"
      assert to_string(Query.text() |> Query.floor()) == ".text | floor()"
      assert to_string(Query.text() |> Query.round()) == ".text | round()"
      assert to_string(Query.text() |> Query.trunc()) == ".text | trunc()"
      assert to_string(Query.text() |> Query.sqrt()) == ".text | sqrt()"
      assert to_string(Query.text() |> Query.pow(2)) == ".text | pow(2)"
      assert to_string(Query.text() |> Query.min(0)) == ".text | min(0)"
      assert to_string(Query.text() |> Query.max(100)) == ".text | max(100)"
      assert to_string(Query.text() |> Query.negate()) == ".text | negate()"
    end

    test "type/logic operations" do
      assert to_string(Query.text() |> Query.type()) == ".text | type"
      assert to_string(Query.text() |> Query.debug()) == ".text | debug"

      assert to_string(Query.text() |> Query.coalesce("default")) ==
               ".text | coalesce(\"default\")"
    end

    test "encoding operations" do
      assert to_string(Query.text() |> Query.base64()) == ".text | base64()"
      assert to_string(Query.text() |> Query.base64d()) == ".text | base64d()"
      assert to_string(Query.text() |> Query.md5()) == ".text | md5()"
      assert to_string(Query.text() |> Query.sha256()) == ".text | sha256()"
      assert to_string(Query.text() |> Query.to_hex()) == ".text | to_hex()"
      assert to_string(Query.text() |> Query.from_hex()) == ".text | from_hex()"
    end

    test "path operations" do
      assert to_string(Query.text() |> Query.basename()) == ".text | basename()"
      assert to_string(Query.text() |> Query.dirname()) == ".text | dirname()"
      assert to_string(Query.text() |> Query.extname()) == ".text | extname()"
      assert to_string(Query.text() |> Query.stem()) == ".text | stem()"

      assert to_string(Query.text() |> Query.path_join("file.md")) ==
               ".text | path_join(\"file.md\")"
    end

    test "dict operations" do
      assert to_string(Query.text() |> Query.get("key")) == ".text | get(\"key\")"
      assert to_string(Query.text() |> Query.set("key", "val")) == ".text | set(\"key\", \"val\")"
    end

    test "markdown mutation operations" do
      assert to_string(Query.h2() |> Query.update("New Title")) == ".h2 | update(\"New Title\")"
      assert to_string(Query.code() |> Query.attr("lang")) == ".code | attr(\"lang\")"

      assert to_string(Query.code() |> Query.set_attr("lang", "ruby")) ==
               ".code | set_attr(\"lang\", \"ruby\")"

      assert to_string(Query.link() |> Query.get_title()) == ".link | get_title"
      assert to_string(Query.link() |> Query.get_url()) == ".link | get_url"
      assert to_string(Query.task() |> Query.set_check(true)) == ".task | set_check(true)"

      assert to_string(Query.link_ref() |> Query.set_ref("myref")) ==
               ".link_ref | set_ref(\"myref\")"

      assert to_string(Query.code() |> Query.set_code_block_lang("ruby")) ==
               ".code | set_code_block_lang(\"ruby\")"

      assert to_string(Query.list() |> Query.set_list_ordered(true)) ==
               ".[] | set_list_ordered(true)"
    end

    test "markdown construction" do
      assert to_string(Query.text() |> Query.to_code("ruby")) == ".text | to_code(\"ruby\")"
      assert to_string(Query.text() |> Query.to_code()) == ".text | to_code(null)"
      assert to_string(Query.text() |> Query.to_code_inline()) == ".text | to_code_inline()"
      assert to_string(Query.text() |> Query.to_h(2)) == ".text | to_h(2)"
      assert to_string(Query.text() |> Query.to_hr()) == ".text | to_hr()"
      assert to_string(Query.text() |> Query.to_strong()) == ".text | to_strong()"
      assert to_string(Query.text() |> Query.to_em()) == ".text | to_em()"
      assert to_string(Query.text() |> Query.to_math()) == ".text | to_math()"
      assert to_string(Query.text() |> Query.to_math_inline()) == ".text | to_math_inline()"
      assert to_string(Query.text() |> Query.to_md_text()) == ".text | to_md_text()"
      assert to_string(Query.text() |> Query.to_md_list(0)) == ".text | to_md_list(0)"

      assert to_string(Query.text() |> Query.to_md_name("component")) ==
               ".text | to_md_name(\"component\")"

      assert to_string(Query.text() |> Query.to_md_table_row(["A", "B", "C"])) ==
               ".text | to_md_table_row(\"A\", \"B\", \"C\")"

      assert to_string(Query.text() |> Query.to_md_table_cell("content", 0, 1)) ==
               ".text | to_md_table_cell(\"content\", 0, 1)"
    end

    test "to_link arities" do
      assert to_string(Query.text() |> Query.to_link("https://example.com")) ==
               ".text | to_link(\"https://example.com\", \"\")"

      assert to_string(Query.text() |> Query.to_link("https://example.com", "Example")) ==
               ".text | to_link(\"https://example.com\", \"Example\", \"\")"

      assert to_string(Query.text() |> Query.to_link("https://example.com", "Example", "title")) ==
               ".text | to_link(\"https://example.com\", \"Example\", \"title\")"
    end

    test "to_image arities" do
      assert to_string(Query.text() |> Query.to_image("img.png")) ==
               ".text | to_image(\"img.png\", \"\")"

      assert to_string(Query.text() |> Query.to_image("img.png", "alt text")) ==
               ".text | to_image(\"img.png\", \"alt text\", \"\")"

      assert to_string(Query.text() |> Query.to_image("img.png", "alt text", "title")) ==
               ".text | to_image(\"img.png\", \"alt text\", \"title\")"
    end

    test "multi-step chain" do
      query =
        Query.h2()
        |> Query.select(Filter.contains("Section"))
        |> Query.to_text()

      assert to_string(query) == ".h2 | select(contains(\"Section\")) | to_text()"
    end

    test "complex chain with combined filters" do
      query =
        Query.h2()
        |> Query.select(
          Filter.contains("API")
          |> Filter.and_filter(Filter.negate(Filter.contains("Internal")))
        )
        |> Query.to_text()
        |> Query.downcase()

      assert to_string(query) ==
               ".h2 | select(contains(\"API\") && not(contains(\"Internal\"))) | to_text() | downcase()"
    end

    test "to_query_string/1" do
      assert Query.to_query_string(Query.h2()) == ".h2"
    end

    test "Inspect protocol" do
      assert inspect(Query.h2()) == "#Mq.Query<.h2>"
    end
  end

  describe "Mq.Query integration with Mq.run/3" do
    test "accepts Query struct" do
      content = "# Main\n\n## Features\n\n## Installation"
      assert {:ok, result} = Mq.run(Query.h2(), content)
      assert result.values == ["## Features", "## Installation"]
    end

    test "filters with select via Query struct" do
      content = "# Main\n\n## Features\n\n## Installation"

      assert {:ok, result} =
               Mq.run(Query.h2() |> Query.select(Filter.contains("Feature")), content)

      assert result.values == ["## Features"]
    end

    test "extracts code block language via chained attribute selector" do
      md = "# Code\n\n```ruby\nputs 'hello'\n```"
      assert {:ok, result} = Mq.run(Query.code() |> Query.lang(), md)
      assert result.values == ["ruby"]
    end

    test "extracts link URLs via chained attribute selector" do
      md = "# Links\n\n[Google](https://google.com)\n\n[GitHub](https://github.com)"
      assert {:ok, result} = Mq.run(Query.link() |> Query.url(), md)
      assert result.values == ["https://google.com", "https://github.com"]
    end

    test "applies downcase transformation" do
      md = "# Hello World"
      assert {:ok, result} = Mq.run(Query.h1() |> Query.to_text() |> Query.downcase(), md)
      assert result.values == ["hello world"]
    end

    test "filters with ends_with via Filter" do
      md = "# Section A\n\n## Section B\n\n### Topic C"
      assert {:ok, result} = Mq.run(Query.heading() |> Query.select(Filter.ends_with("B")), md)
      assert result.values == ["## Section B"]
    end

    test "combined AND filter" do
      md = "# Section A\n\n## API Guide\n\n## Internal API\n\n## Installation"

      query =
        Query.h2()
        |> Query.select(
          Filter.contains("API")
          |> Filter.and_filter(Filter.negate(Filter.contains("Internal")))
        )

      assert {:ok, result} = Mq.run(query, md)
      assert result.values == ["## API Guide"]
    end

    test "combined OR filter with Filter.any/1" do
      md = "# Main\n\n## Features\n\n## Installation\n\n## Contributing"

      query =
        Query.h2()
        |> Query.select(Filter.any([Filter.contains("Feature"), Filter.contains("Install")]))

      assert {:ok, result} = Mq.run(query, md)
      assert result.values == ["## Features", "## Installation"]
    end

    test "plain string still works" do
      content = "# Main\n\n## Features\n\n## Installation"
      assert {:ok, result} = Mq.run(".h2", content)
      assert result.values == ["## Features", "## Installation"]
    end

    test "ascii_upcase transformation (mq 0.6.4)" do
      md = "Hello world"
      assert {:ok, result} = Mq.run(Query.text() |> Query.ascii_upcase(), md)
      assert result.values == ["HELLO WORLD"]
    end

    test "url_decode transformation (mq 0.6.4)" do
      md = "hello%20world"
      assert {:ok, result} = Mq.run(Query.text() |> Query.url_decode(), md)
      assert result.values == ["hello world"]
    end

    test "scan finds all regex matches (mq 0.6.4)" do
      md = "Hello world"
      assert {:ok, result} = Mq.run(Query.text() |> Query.scan("\\w+"), md)
      assert result.values == ["Hello\nworld"]
    end

    test "standalone uuid generates a UUID string (mq 0.6.4)" do
      assert {:ok, result} = Mq.run(Query.uuid(), "# x")
      assert [uuid] = result.values
      assert String.match?(uuid, ~r/^[0-9a-f-]{36}$/)
    end
  end

  describe "Mq.Filter" do
    test "string matching filters" do
      assert to_string(Filter.contains("foo")) == "contains(\"foo\")"
      assert to_string(Filter.starts_with("foo")) == "starts_with(\"foo\")"
      assert to_string(Filter.ends_with("foo")) == "ends_with(\"foo\")"
    end

    test "comparison filters" do
      assert to_string(Filter.eq("foo")) == "eq(\"foo\")"
      assert to_string(Filter.ne("foo")) == "ne(\"foo\")"
      assert to_string(Filter.gt(5)) == "gt(5)"
      assert to_string(Filter.gte(5)) == "gte(5)"
      assert to_string(Filter.lt(5)) == "lt(5)"
      assert to_string(Filter.lte(5)) == "lte(5)"
    end

    test "type check filters" do
      assert to_string(Filter.mdx?()) == "is_mdx()"
      assert to_string(Filter.none?()) == "is_none()"
      assert to_string(Filter.nan?()) == "is_nan()"
      assert to_string(Filter.type()) == "type"
    end

    test "and_filter/2 combines with AND" do
      f = Filter.contains("foo") |> Filter.and_filter(Filter.starts_with("bar"))
      assert to_string(f) == "contains(\"foo\") && starts_with(\"bar\")"
    end

    test "or_filter/2 combines with OR" do
      f = Filter.contains("foo") |> Filter.or_filter(Filter.contains("bar"))
      assert to_string(f) == "contains(\"foo\") || contains(\"bar\")"
    end

    test "all/1 combines list with AND" do
      f = Filter.all([Filter.contains("A"), Filter.contains("B"), Filter.contains("C")])
      assert to_string(f) == "contains(\"A\") && contains(\"B\") && contains(\"C\")"
    end

    test "any/1 combines list with OR" do
      f = Filter.any([Filter.contains("A"), Filter.contains("B")])
      assert to_string(f) == "contains(\"A\") || contains(\"B\")"
    end

    test "negate/1 wraps with not()" do
      f = Filter.negate(Filter.contains("draft"))
      assert to_string(f) == "not(contains(\"draft\"))"
    end

    test "Inspect protocol" do
      assert inspect(Filter.contains("foo")) == "#Mq.Filter<contains(\"foo\")>"
    end

    test "triple-combine with AND" do
      f =
        Filter.contains("API")
        |> Filter.and_filter(Filter.negate(Filter.contains("Internal")))
        |> Filter.and_filter(Filter.starts_with("## "))

      assert to_string(f) ==
               "contains(\"API\") && not(contains(\"Internal\")) && starts_with(\"## \")"
    end
  end
end
