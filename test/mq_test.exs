defmodule MqTest do
  use ExUnit.Case, async: true
  doctest Mq

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
end
