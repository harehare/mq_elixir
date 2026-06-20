defmodule Mq do
  @moduledoc """
  Elixir bindings for the mq markdown processing library.

  ## Features

  - Process markdown, MDX, HTML, and plain text
  - Full mq query language support
  - Multiple input and output format options
  - Configurable rendering options

  ## Installation

  Add `mq` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:mq, "~> 0.5.9"}
        ]
      end

  ## Usage

      # Raw query string
      {:ok, result} = Mq.run(".h1", "# Hello\\n## World")
      IO.inspect(result.values)  # ["# Hello"]

      # Query builder — use Mq directly as the entry point
      {:ok, result} =
        Mq.h2()
        |> Mq.select(Mq.Filter.contains("Feature"))
        |> Mq.to_text()
        |> Mq.run(content)

      # With options
      options = %Mq.Options{input_format: :markdown}
      {:ok, result} = Mq.run(".h2", markdown_content, options)

      # HTML to Markdown conversion
      {:ok, markdown} = Mq.html_to_markdown("<h1>Hello</h1>")
  """

  alias Mq.{ConversionOptions, Native, Options, Query, Result}

  @doc """
  Run an mq query on the provided content.

  Accepts either a raw query string or an `Mq.Query` struct built with the
  query builder functions on this module.

  ## Parameters

  - `code` - The mq query string or an `%Mq.Query{}` struct
  - `content` - The markdown/HTML/text content to process
  - `options` - Optional configuration (defaults to `%Mq.Options{}`)

  ## Returns

  - `{:ok, %Mq.Result{}}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> Mq.run(".h1", "# Title\\n## Subtitle")
      {:ok, %Mq.Result{values: ["# Title"], text: "# Title"}}

      iex> options = %Mq.Options{input_format: :text}
      iex> {:ok, _result} = Mq.run("select(contains(\\"test\\"))", "line1\\ntest line\\nline3", options)
      {:ok, %Mq.Result{values: ["test line"], text: "test line"}}

      iex> {:ok, result} = Mq.h2() |> Mq.select(Mq.Filter.contains("World")) |> Mq.run("# Hello\\n## World\\n## Other")
      iex> result.values
      ["## World"]
  """
  @spec run(String.t() | Query.t(), String.t(), Options.t() | nil) ::
          {:ok, Result.t()} | {:error, String.t()}
  def run(code, content, options \\ nil) do
    query_string =
      case code do
        %Query{} -> Query.to_query_string(code)
        str when is_binary(str) -> str
      end

    opts = options || %Options{}

    case Native.run(query_string, content, Options.to_map(opts)) do
      {:ok, result_map} -> {:ok, Result.from_map(result_map)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Convert HTML to Markdown.

  ## Parameters

  - `content` - The HTML content to convert
  - `options` - Optional conversion options

  ## Returns

  - `{:ok, markdown_string}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> Mq.html_to_markdown("<h1>Hello</h1><p>World</p>")
      {:ok, "# Hello\\n\\nWorld"}

      iex> html_content = "<html><head><title>Title</title></head><body><h1>Content</h1></body></html>"
      iex> opts = %Mq.ConversionOptions{use_title_as_h1: true}
      iex> {:ok, markdown} = Mq.html_to_markdown(html_content, opts)
      {:ok, markdown}
  """
  @spec html_to_markdown(String.t(), ConversionOptions.t() | nil) ::
          {:ok, String.t()} | {:error, String.t()}
  def html_to_markdown(content, options \\ nil) do
    opts = options || %ConversionOptions{}

    case Native.html_to_markdown(content, ConversionOptions.to_map(opts)) do
      result when is_binary(result) -> {:ok, result}
      {:error, _} = error -> error
    end
  end

  # Query builder — delegated from Mq.Query
  #
  # All `Mq.Query` functions are available directly on `Mq`, so you can write:
  #
  #     Mq.h2()
  #     |> Mq.select(Mq.Filter.contains("Feature"))
  #     |> Mq.to_text()
  #     |> Mq.run(content)
  #
  # See `Mq.Query` for full documentation on each function.

  # Heading selectors
  defdelegate h1(), to: Query
  defdelegate h2(), to: Query
  defdelegate h3(), to: Query
  defdelegate h4(), to: Query
  defdelegate h5(), to: Query
  defdelegate h6(), to: Query
  defdelegate heading(), to: Query

  # Block element selectors
  defdelegate code(), to: Query
  defdelegate paragraph(), to: Query
  defdelegate blockquote(), to: Query
  defdelegate hr(), to: Query
  defdelegate image(), to: Query
  defdelegate link(), to: Query
  defdelegate text(), to: Query
  defdelegate strong(), to: Query
  defdelegate emphasis(), to: Query
  defdelegate delete(), to: Query
  defdelegate math(), to: Query
  defdelegate table(), to: Query
  defdelegate table_align(), to: Query
  defdelegate html(), to: Query
  defdelegate definition(), to: Query
  defdelegate footnote(), to: Query
  defdelegate toml(), to: Query
  defdelegate yaml(), to: Query

  # Inline element selectors
  defdelegate code_inline(), to: Query
  defdelegate math_inline(), to: Query
  defdelegate link_ref(), to: Query
  defdelegate image_ref(), to: Query
  defdelegate footnote_ref(), to: Query
  defdelegate line_break(), to: Query

  # Task list selectors
  defdelegate task(), to: Query
  defdelegate todo(), to: Query
  defdelegate done(), to: Query

  # List / table selectors
  defdelegate list(), to: Query
  defdelegate list_at(n), to: Query
  defdelegate table_row(n), to: Query
  defdelegate table_col(n), to: Query
  defdelegate table_cell(r, c), to: Query

  # MDX selectors
  defdelegate mdx_jsx_flow_element(), to: Query
  defdelegate mdx_text_expression(), to: Query
  defdelegate mdx_jsx_text_element(), to: Query
  defdelegate mdx_flow_expression(), to: Query
  defdelegate mdx_js_esm(), to: Query

  # Recursive selector
  defdelegate recursive(), to: Query

  # Standalone attribute selectors (0-arity)
  defdelegate value(), to: Query
  defdelegate node_values(), to: Query
  defdelegate lang(), to: Query
  defdelegate meta(), to: Query
  defdelegate fence(), to: Query
  defdelegate url(), to: Query
  defdelegate alt(), to: Query
  defdelegate depth(), to: Query
  defdelegate level(), to: Query
  defdelegate ordered(), to: Query
  defdelegate checked(), to: Query
  defdelegate column(), to: Query
  defdelegate row(), to: Query
  defdelegate align(), to: Query
  defdelegate property(key), to: Query

  # Standalone select (no leading selector)
  defdelegate select(filter), to: Query

  # Chain operations
  defdelegate select(query, filter), to: Query
  defdelegate map(query, filter), to: Query

  # Output format conversions
  defdelegate to_text(query), to: Query
  defdelegate to_markdown(query), to: Query
  defdelegate to_mdx(query), to: Query
  defdelegate to_html(query), to: Query
  defdelegate stringify(query), to: Query
  defdelegate to_number(query), to: Query
  defdelegate to_array(query), to: Query
  defdelegate to_bytes(query), to: Query
  defdelegate to_markdown_string(query), to: Query

  # Collection operations
  defdelegate length(query), to: Query
  defdelegate len(query), to: Query
  defdelegate utf8bytelen(query), to: Query
  defdelegate add(query, other), to: Query
  defdelegate first(query), to: Query
  defdelegate last(query), to: Query
  defdelegate empty(query), to: Query
  defdelegate reverse(query), to: Query
  defdelegate sort(query), to: Query
  defdelegate compact(query), to: Query
  defdelegate uniq(query), to: Query
  defdelegate flatten(query), to: Query
  defdelegate keys(query), to: Query
  defdelegate values(query), to: Query
  defdelegate entries(query), to: Query
  defdelegate children(query), to: Query
  defdelegate split(query, sep), to: Query
  defdelegate join(query, sep), to: Query
  defdelegate nth(query, n), to: Query
  defdelegate limit(query, n), to: Query
  defdelegate range(query, n), to: Query
  defdelegate slice(query, start, stop), to: Query
  defdelegate index(query, value), to: Query
  defdelegate rindex(query, value), to: Query
  defdelegate del(query, value), to: Query
  defdelegate insert(query, idx, val), to: Query
  defdelegate repeat(query, n), to: Query

  # String operations
  defdelegate trim(query), to: Query
  defdelegate ltrim(query), to: Query
  defdelegate rtrim(query), to: Query
  defdelegate downcase(query), to: Query
  defdelegate upcase(query), to: Query
  defdelegate explode(query), to: Query
  defdelegate implode(query), to: Query
  defdelegate url_encode(query), to: Query
  defdelegate intern(query), to: Query
  defdelegate gsub(query, pattern, replacement), to: Query
  defdelegate replace(query, from, to), to: Query
  defdelegate test(query, pattern), to: Query
  defdelegate capture(query, pattern), to: Query

  # Math operations
  defdelegate abs(query), to: Query
  defdelegate ceil(query), to: Query
  defdelegate floor(query), to: Query
  defdelegate round(query), to: Query
  defdelegate trunc(query), to: Query
  defdelegate sqrt(query), to: Query
  defdelegate ln(query), to: Query
  defdelegate log10(query), to: Query
  defdelegate exp(query), to: Query
  defdelegate negate(query), to: Query
  defdelegate nan?(query), to: Query
  defdelegate pow(query, n), to: Query
  defdelegate min(query, other), to: Query
  defdelegate max(query, other), to: Query

  # Type / logic
  defdelegate type(query), to: Query
  defdelegate debug(query), to: Query
  defdelegate coalesce(query, default), to: Query

  # Encoding
  defdelegate base64(query), to: Query
  defdelegate base64d(query), to: Query
  defdelegate base64url(query), to: Query
  defdelegate base64urld(query), to: Query
  defdelegate md5(query), to: Query
  defdelegate sha256(query), to: Query
  defdelegate sha512(query), to: Query
  defdelegate from_hex(query), to: Query
  defdelegate to_hex(query), to: Query

  # Path operations
  defdelegate basename(query), to: Query
  defdelegate dirname(query), to: Query
  defdelegate extname(query), to: Query
  defdelegate stem(query), to: Query
  defdelegate path_join(query, other), to: Query

  # Dict operations
  defdelegate get(query, key), to: Query
  defdelegate set(query, key, val), to: Query

  # Chained attribute selectors (1-arity)
  defdelegate value(query), to: Query
  defdelegate lang(query), to: Query
  defdelegate meta(query), to: Query
  defdelegate fence(query), to: Query
  defdelegate url(query), to: Query
  defdelegate alt(query), to: Query
  defdelegate title(query), to: Query
  defdelegate ident(query), to: Query
  defdelegate label(query), to: Query
  defdelegate depth(query), to: Query
  defdelegate level(query), to: Query
  defdelegate item_index(query), to: Query
  defdelegate ordered(query), to: Query
  defdelegate checked(query), to: Query
  defdelegate column(query), to: Query
  defdelegate row(query), to: Query
  defdelegate align(query), to: Query
  defdelegate mdx_name(query), to: Query
  defdelegate property(query, key), to: Query

  # Markdown mutation
  defdelegate update(query, content), to: Query
  defdelegate attr(query, name), to: Query
  defdelegate set_attr(query, name, val), to: Query
  defdelegate get_title(query), to: Query
  defdelegate get_url(query), to: Query
  defdelegate set_check(query, val), to: Query
  defdelegate set_ref(query, ref), to: Query
  defdelegate set_code_block_lang(query, lang), to: Query
  defdelegate set_list_ordered(query, val), to: Query

  # Markdown construction
  defdelegate to_code(query), to: Query
  defdelegate to_code(query, lang), to: Query
  defdelegate to_code_inline(query), to: Query
  defdelegate to_h(query, depth), to: Query
  defdelegate to_hr(query), to: Query
  defdelegate to_link(query, url), to: Query
  defdelegate to_link(query, url, text), to: Query
  defdelegate to_link(query, url, text, link_title), to: Query
  defdelegate to_image(query, url), to: Query
  defdelegate to_image(query, url, img_alt), to: Query
  defdelegate to_image(query, url, img_alt, img_title), to: Query
  defdelegate to_math(query), to: Query
  defdelegate to_math_inline(query), to: Query
  defdelegate to_strong(query), to: Query
  defdelegate to_em(query), to: Query
  defdelegate to_md_text(query), to: Query
  defdelegate to_md_list(query, list_level), to: Query
  defdelegate to_md_name(query, node_name), to: Query
  defdelegate to_md_table_row(query, cells), to: Query
  defdelegate to_md_table_cell(query, content, r, c), to: Query

  # Conversion
  defdelegate to_query_string(query), to: Query
end
