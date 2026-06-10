defmodule Mq.Query do
  @moduledoc """
  Programmatic query builder for constructing mq queries.

  Queries are built by starting with a **selector** (e.g. `h2/0`, `code/0`) and
  chaining operations via the `|>` pipe operator. The resulting struct can be
  passed directly to `Mq.run/3` or converted to its string form with
  `to_string/1` / `Kernel.to_string/1`.

  ## Basic usage

      iex> Mq.Query.h2() |> to_string()
      ".h2"

      iex> Mq.Query.h2() |> Mq.Query.to_text() |> to_string()
      ".h2 | to_text()"

  ## Filters

  Use `Mq.Filter` to build filter expressions for `select/2` and `map/2`:

      iex> alias Mq.{Query, Filter}
      iex> Query.h2() |> Query.select(Filter.contains("Feature")) |> to_string()
      ".h2 | select(contains(\\"Feature\\"))"

  ## Combined filters

      iex> alias Mq.{Query, Filter}
      iex> query = Query.h2()
      ...>   |> Query.select(
      ...>     Filter.contains("API")
      ...>     |> Filter.and_filter(Filter.negate(Filter.contains("Internal")))
      ...>   )
      ...>   |> Query.to_text()
      ...>   |> Query.downcase()
      iex> to_string(query)
      ".h2 | select(contains(\\"API\\") and not(contains(\\"Internal\\"))) | to_text() | downcase()"

  ## Using with `Mq.run/3`

      iex> {:ok, result} = Mq.run(Mq.Query.h2(), "# Hello\\n## World")
      iex> result.values
      ["## World"]
  """

  @type t :: %__MODULE__{expr: String.t()}

  defstruct [:expr]

  defp new(expr), do: %__MODULE__{expr: expr}

  defp pipe_expr(%__MODULE__{expr: ""}, next), do: new(next)
  defp pipe_expr(%__MODULE__{expr: expr}, next), do: new("#{expr} | #{next}")

  # ── Heading selectors ─────────────────────────────────────────────────────

  for n <- 1..6 do
    @doc "Select all h#{n} headings."
    def unquote(:"h#{n}")(), do: new(unquote(".h#{n}"))
  end

  @doc "Select all headings (any level)."
  def heading(), do: new(".heading")

  # ── Block element selectors ───────────────────────────────────────────────

  @doc "Select all code blocks."
  def code(), do: new(".code")

  @doc "Select all paragraphs."
  def paragraph(), do: new(".p")

  @doc "Select all blockquotes."
  def blockquote(), do: new(".blockquote")

  @doc "Select all horizontal rules."
  def hr(), do: new(".hr")

  @doc "Select all images."
  def image(), do: new(".image")

  @doc "Select all links."
  def link(), do: new(".link")

  @doc "Select all text nodes."
  def text(), do: new(".text")

  @doc "Select all strong (bold) nodes."
  def strong(), do: new(".strong")

  @doc "Select all emphasis (italic) nodes."
  def emphasis(), do: new(".emphasis")

  @doc "Select all strikethrough (delete) nodes."
  def delete(), do: new(".delete")

  @doc "Select all math blocks."
  def math(), do: new(".math")

  @doc "Select all tables."
  def table(), do: new(".table")

  @doc "Select all table alignment nodes."
  def table_align(), do: new(".table_align")

  @doc "Select all raw HTML nodes."
  def html(), do: new(".html")

  @doc "Select all link definition nodes."
  def definition(), do: new(".definition")

  @doc "Select all footnote definition nodes."
  def footnote(), do: new(".footnote")

  @doc "Select all TOML front matter nodes."
  def toml(), do: new(".toml")

  @doc "Select all YAML front matter nodes."
  def yaml(), do: new(".yaml")

  # ── Inline element selectors ──────────────────────────────────────────────

  @doc "Select all inline code spans."
  def code_inline(), do: new(".code_inline")

  @doc "Select all inline math spans."
  def math_inline(), do: new(".math_inline")

  @doc "Select all link reference nodes."
  def link_ref(), do: new(".link_ref")

  @doc "Select all image reference nodes."
  def image_ref(), do: new(".image_ref")

  @doc "Select all footnote reference nodes."
  def footnote_ref(), do: new(".footnote_ref")

  @doc "Select all line break nodes."
  def line_break(), do: new(".break")

  # ── Task list selectors ───────────────────────────────────────────────────

  @doc "Select all task list items."
  def task(), do: new(".task")

  @doc "Select all unchecked task list items."
  def todo(), do: new(".todo")

  @doc "Select all checked task list items."
  def done(), do: new(".done")

  # ── List and table selectors ──────────────────────────────────────────────

  @doc "Select all list items."
  def list(), do: new(".[]")

  @doc "Select the list item at index `n`."
  def list_at(n), do: new(".[#{n}]")

  @doc "Select all cells in table row `n`."
  def table_row(n), do: new(".[#{n}][]")

  @doc "Select all cells in table column `n`."
  def table_col(n), do: new(".[][#{n}]")

  @doc "Select the table cell at row `r`, column `c`."
  def table_cell(r, c), do: new(".[#{r}][#{c}]")

  # ── MDX selectors ─────────────────────────────────────────────────────────

  @doc "Select all MDX JSX flow elements."
  def mdx_jsx_flow_element(), do: new(".mdx_jsx_flow_element")

  @doc "Select all MDX text expression nodes."
  def mdx_text_expression(), do: new(".mdx_text_expression")

  @doc "Select all MDX JSX text elements."
  def mdx_jsx_text_element(), do: new(".mdx_jsx_text_element")

  @doc "Select all MDX flow expression nodes."
  def mdx_flow_expression(), do: new(".mdx_flow_expression")

  @doc "Select all MDX JS/ESM import/export nodes."
  def mdx_js_esm(), do: new(".mdx_js_esm")

  # ── Recursive (deep) selector ─────────────────────────────────────────────

  @doc "Recursive / deep selector — descend into all children."
  def recursive(), do: new("..")

  # ── Standalone attribute selectors (0-arity) ──────────────────────────────
  # These also exist as 1-arity chain operations below.

  @doc "Standalone `.value` attribute selector."
  def value(), do: new(".value")

  @doc "Standalone `.values` attribute selector."
  def node_values(), do: new(".values")

  @doc "Standalone `.lang` attribute selector."
  def lang(), do: new(".lang")

  @doc "Standalone `.meta` attribute selector."
  def meta(), do: new(".meta")

  @doc "Standalone `.fence` attribute selector."
  def fence(), do: new(".fence")

  @doc "Standalone `.url` attribute selector."
  def url(), do: new(".url")

  @doc "Standalone `.alt` attribute selector."
  def alt(), do: new(".alt")

  @doc "Standalone `.depth` attribute selector."
  def depth(), do: new(".depth")

  @doc "Standalone `.level` attribute selector."
  def level(), do: new(".level")

  @doc "Standalone `.ordered` attribute selector."
  def ordered(), do: new(".ordered")

  @doc "Standalone `.checked` attribute selector."
  def checked(), do: new(".checked")

  @doc "Standalone `.column` attribute selector."
  def column(), do: new(".column")

  @doc "Standalone `.row` attribute selector."
  def row(), do: new(".row")

  @doc "Standalone `.align` attribute selector."
  def align(), do: new(".align")

  @doc "Standalone dict property selector: `.\"key\"`."
  def property(key), do: new(".\"#{key}\"")

  # ── Standalone select (no leading selector) ───────────────────────────────

  @doc """
  Standalone `select(filter)` — no leading selector.

      Query.select(Filter.is_mdx())
      # => "select(is_mdx())"
  """
  def select(%Mq.Filter{expr: expr}), do: new("select(#{expr})")
  def select(filter) when is_binary(filter), do: new("select(#{filter})")

  # ── Chained operations ────────────────────────────────────────────────────

  @doc "Append a `select(filter)` step."
  def select(%__MODULE__{} = q, %Mq.Filter{expr: expr}), do: pipe_expr(q, "select(#{expr})")
  def select(%__MODULE__{} = q, filter) when is_binary(filter), do: pipe_expr(q, "select(#{filter})")

  @doc "Append a `map(filter)` step."
  def map(%__MODULE__{} = q, %Mq.Filter{expr: expr}), do: pipe_expr(q, "map(#{expr})")
  def map(%__MODULE__{} = q, filter) when is_binary(filter), do: pipe_expr(q, "map(#{filter})")

  # ── Output format conversions ─────────────────────────────────────────────

  @doc "Convert to plain text."
  def to_text(%__MODULE__{} = q), do: pipe_expr(q, "to_text()")

  @doc "Convert to Markdown."
  def to_markdown(%__MODULE__{} = q), do: pipe_expr(q, "to_markdown()")

  @doc "Convert to MDX."
  def to_mdx(%__MODULE__{} = q), do: pipe_expr(q, "to_mdx()")

  @doc "Convert to HTML."
  def to_html(%__MODULE__{} = q), do: pipe_expr(q, "to_html()")

  @doc "Convert to a string value (mq `to_string()` function)."
  def stringify(%__MODULE__{} = q), do: pipe_expr(q, "to_string()")

  @doc "Convert to a number value."
  def to_number(%__MODULE__{} = q), do: pipe_expr(q, "to_number()")

  @doc "Convert to an array value."
  def to_array(%__MODULE__{} = q), do: pipe_expr(q, "to_array()")

  @doc "Convert to bytes."
  def to_bytes(%__MODULE__{} = q), do: pipe_expr(q, "to_bytes()")

  @doc "Convert to a Markdown string (serialized)."
  def to_markdown_string(%__MODULE__{} = q), do: pipe_expr(q, "to_markdown_string()")

  # ── Collection operations ─────────────────────────────────────────────────

  @doc "Return the length of the current value."
  def length(%__MODULE__{} = q), do: pipe_expr(q, "length")

  @doc "Return the byte length of the current value."
  def len(%__MODULE__{} = q), do: pipe_expr(q, "len()")

  @doc "Return the UTF-8 byte length of the current value."
  def utf8bytelen(%__MODULE__{} = q), do: pipe_expr(q, "utf8bytelen()")

  @doc "Add/concatenate the current value."
  def add(%__MODULE__{} = q), do: pipe_expr(q, "add")

  @doc "Return the first element."
  def first(%__MODULE__{} = q), do: pipe_expr(q, "first")

  @doc "Return the last element."
  def last(%__MODULE__{} = q), do: pipe_expr(q, "last")

  @doc "Emit nothing (empty result)."
  def empty(%__MODULE__{} = q), do: pipe_expr(q, "empty")

  @doc "Reverse the current value."
  def reverse(%__MODULE__{} = q), do: pipe_expr(q, "reverse")

  @doc "Sort the current value."
  def sort(%__MODULE__{} = q), do: pipe_expr(q, "sort")

  @doc "Remove nil/null entries."
  def compact(%__MODULE__{} = q), do: pipe_expr(q, "compact")

  @doc "Remove duplicate entries."
  def uniq(%__MODULE__{} = q), do: pipe_expr(q, "uniq")

  @doc "Flatten nested arrays."
  def flatten(%__MODULE__{} = q), do: pipe_expr(q, "flatten")

  @doc "Return the keys of a dict."
  def keys(%__MODULE__{} = q), do: pipe_expr(q, "keys")

  @doc "Return the values of a dict."
  def values(%__MODULE__{} = q), do: pipe_expr(q, "values")

  @doc "Return the key-value entries of a dict."
  def entries(%__MODULE__{} = q), do: pipe_expr(q, "entries")

  @doc "Descend into children."
  def children(%__MODULE__{} = q), do: pipe_expr(q, ".children")

  @doc "Split the current value by `sep`."
  def split(%__MODULE__{} = q, sep), do: pipe_expr(q, "split(#{inspect(sep)})")

  @doc "Join elements with `sep`."
  def join(%__MODULE__{} = q, sep), do: pipe_expr(q, "join(#{inspect(sep)})")

  @doc "Select the nth element (0-based)."
  def nth(%__MODULE__{} = q, n), do: pipe_expr(q, "nth(#{n})")

  @doc "Limit output to `n` elements."
  def limit(%__MODULE__{} = q, n), do: pipe_expr(q, "limit(#{n})")

  @doc "Take a range of `n` elements."
  def range(%__MODULE__{} = q, n), do: pipe_expr(q, "range(#{n})")

  @doc "Slice elements from `start` to `stop`."
  def slice(%__MODULE__{} = q, start, stop), do: pipe_expr(q, "slice(#{start}, #{stop})")

  @doc "Find the first index of `value`."
  def index(%__MODULE__{} = q, value), do: pipe_expr(q, "index(#{inspect(value)})")

  @doc "Find the last index of `value`."
  def rindex(%__MODULE__{} = q, value), do: pipe_expr(q, "rindex(#{inspect(value)})")

  @doc "Delete the element `value`."
  def del(%__MODULE__{} = q, value), do: pipe_expr(q, "del(#{inspect(value)})")

  @doc "Insert `val` at index `idx`."
  def insert(%__MODULE__{} = q, idx, val), do: pipe_expr(q, "insert(#{idx}, #{inspect(val)})")

  @doc "Repeat the current value `n` times."
  def repeat(%__MODULE__{} = q, n), do: pipe_expr(q, "repeat(#{n})")

  # ── String operations ─────────────────────────────────────────────────────

  @doc "Trim leading and trailing whitespace."
  def trim(%__MODULE__{} = q), do: pipe_expr(q, "trim()")

  @doc "Trim leading whitespace."
  def ltrim(%__MODULE__{} = q), do: pipe_expr(q, "ltrim()")

  @doc "Trim trailing whitespace."
  def rtrim(%__MODULE__{} = q), do: pipe_expr(q, "rtrim()")

  @doc "Convert to lowercase (Unicode-aware)."
  def downcase(%__MODULE__{} = q), do: pipe_expr(q, "downcase()")

  @doc "Convert to uppercase (Unicode-aware)."
  def upcase(%__MODULE__{} = q), do: pipe_expr(q, "upcase()")

  @doc "Convert to lowercase (ASCII only)."
  def ascii_downcase(%__MODULE__{} = q), do: pipe_expr(q, "ascii_downcase()")

  @doc "Convert to uppercase (ASCII only)."
  def ascii_upcase(%__MODULE__{} = q), do: pipe_expr(q, "ascii_upcase()")

  @doc "Explode a string into codepoints."
  def explode(%__MODULE__{} = q), do: pipe_expr(q, "explode()")

  @doc "Implode codepoints back into a string."
  def implode(%__MODULE__{} = q), do: pipe_expr(q, "implode()")

  @doc "URL-encode the current value."
  def url_encode(%__MODULE__{} = q), do: pipe_expr(q, "url_encode()")

  @doc "Intern the current string."
  def intern(%__MODULE__{} = q), do: pipe_expr(q, "intern()")

  @doc "Replace all occurrences of `pattern` with `replacement` (regex)."
  def gsub(%__MODULE__{} = q, pattern, replacement),
    do: pipe_expr(q, "gsub(#{inspect(pattern)}, #{inspect(replacement)})")

  @doc "Replace the first occurrence of `from` with `to`."
  def replace(%__MODULE__{} = q, from, to),
    do: pipe_expr(q, "replace(#{inspect(from)}, #{inspect(to)})")

  @doc "Test whether the current value matches `pattern` (regex)."
  def test(%__MODULE__{} = q, pattern), do: pipe_expr(q, "test(#{inspect(pattern)})")

  @doc "Capture groups from `pattern` (regex)."
  def capture(%__MODULE__{} = q, pattern), do: pipe_expr(q, "capture(#{inspect(pattern)})")

  # ── Math operations ───────────────────────────────────────────────────────

  @doc "Absolute value."
  def abs(%__MODULE__{} = q), do: pipe_expr(q, "abs()")

  @doc "Ceiling."
  def ceil(%__MODULE__{} = q), do: pipe_expr(q, "ceil()")

  @doc "Floor."
  def floor(%__MODULE__{} = q), do: pipe_expr(q, "floor()")

  @doc "Round."
  def round(%__MODULE__{} = q), do: pipe_expr(q, "round()")

  @doc "Truncate."
  def trunc(%__MODULE__{} = q), do: pipe_expr(q, "trunc()")

  @doc "Square root."
  def sqrt(%__MODULE__{} = q), do: pipe_expr(q, "sqrt()")

  @doc "Natural logarithm."
  def ln(%__MODULE__{} = q), do: pipe_expr(q, "ln()")

  @doc "Base-10 logarithm."
  def log10(%__MODULE__{} = q), do: pipe_expr(q, "log10()")

  @doc "Exponential (e^x)."
  def exp(%__MODULE__{} = q), do: pipe_expr(q, "exp()")

  @doc "Negate the current numeric value."
  def negate(%__MODULE__{} = q), do: pipe_expr(q, "negate()")

  @doc "Check whether the current value is NaN."
  def is_nan(%__MODULE__{} = q), do: pipe_expr(q, "is_nan()")

  @doc "Raise the current value to the power of `n`."
  def pow(%__MODULE__{} = q, n), do: pipe_expr(q, "pow(#{n})")

  @doc "Return the smaller of the current value and `other`."
  def min(%__MODULE__{} = q, other), do: pipe_expr(q, "min(#{other})")

  @doc "Return the larger of the current value and `other`."
  def max(%__MODULE__{} = q, other), do: pipe_expr(q, "max(#{other})")

  # ── Type / logic ──────────────────────────────────────────────────────────

  @doc "Return the type of the current value."
  def type(%__MODULE__{} = q), do: pipe_expr(q, "type")

  @doc "Emit debug information for the current value."
  def debug(%__MODULE__{} = q), do: pipe_expr(q, "debug")

  @doc "Return `default` when the current value is none/null."
  def coalesce(%__MODULE__{} = q, default), do: pipe_expr(q, "coalesce(#{inspect(default)})")

  # ── Encoding ──────────────────────────────────────────────────────────────

  @doc "Base64-encode."
  def base64(%__MODULE__{} = q), do: pipe_expr(q, "base64()")

  @doc "Base64-decode."
  def base64d(%__MODULE__{} = q), do: pipe_expr(q, "base64d()")

  @doc "Base64url-encode."
  def base64url(%__MODULE__{} = q), do: pipe_expr(q, "base64url()")

  @doc "Base64url-decode."
  def base64urld(%__MODULE__{} = q), do: pipe_expr(q, "base64urld()")

  @doc "MD5 hash."
  def md5(%__MODULE__{} = q), do: pipe_expr(q, "md5()")

  @doc "SHA-256 hash."
  def sha256(%__MODULE__{} = q), do: pipe_expr(q, "sha256()")

  @doc "SHA-512 hash."
  def sha512(%__MODULE__{} = q), do: pipe_expr(q, "sha512()")

  @doc "Decode from hex."
  def from_hex(%__MODULE__{} = q), do: pipe_expr(q, "from_hex()")

  @doc "Encode to hex."
  def to_hex(%__MODULE__{} = q), do: pipe_expr(q, "to_hex()")

  # ── Path operations ───────────────────────────────────────────────────────

  @doc "Return the basename of a path."
  def basename(%__MODULE__{} = q), do: pipe_expr(q, "basename()")

  @doc "Return the directory part of a path."
  def dirname(%__MODULE__{} = q), do: pipe_expr(q, "dirname()")

  @doc "Return the file extension."
  def extname(%__MODULE__{} = q), do: pipe_expr(q, "extname()")

  @doc "Return the filename stem (basename without extension)."
  def stem(%__MODULE__{} = q), do: pipe_expr(q, "stem()")

  @doc "Join the current path with `other`."
  def path_join(%__MODULE__{} = q, other), do: pipe_expr(q, "path_join(#{inspect(other)})")

  # ── Dict operations ───────────────────────────────────────────────────────

  @doc "Get the value at dict key `key`."
  def get(%__MODULE__{} = q, key), do: pipe_expr(q, "get(#{inspect(key)})")

  @doc "Set dict key `key` to `val`."
  def set(%__MODULE__{} = q, key, val), do: pipe_expr(q, "set(#{inspect(key)}, #{inspect(val)})")

  # ── Chained attribute selectors (1-arity, dual with standalone 0-arity) ───

  @doc "Access the `.value` attribute of the selected node."
  def value(%__MODULE__{} = q), do: pipe_expr(q, ".value")

  @doc "Access the `.lang` attribute (e.g. code block language)."
  def lang(%__MODULE__{} = q), do: pipe_expr(q, ".lang")

  @doc "Access the `.meta` attribute."
  def meta(%__MODULE__{} = q), do: pipe_expr(q, ".meta")

  @doc "Access the `.fence` attribute."
  def fence(%__MODULE__{} = q), do: pipe_expr(q, ".fence")

  @doc "Access the `.url` attribute."
  def url(%__MODULE__{} = q), do: pipe_expr(q, ".url")

  @doc "Access the `.alt` attribute."
  def alt(%__MODULE__{} = q), do: pipe_expr(q, ".alt")

  @doc "Access the `.title` attribute."
  def title(%__MODULE__{} = q), do: pipe_expr(q, ".title")

  @doc "Access the `.ident` attribute."
  def ident(%__MODULE__{} = q), do: pipe_expr(q, ".ident")

  @doc "Access the `.label` attribute."
  def label(%__MODULE__{} = q), do: pipe_expr(q, ".label")

  @doc "Access the `.depth` attribute."
  def depth(%__MODULE__{} = q), do: pipe_expr(q, ".depth")

  @doc "Access the `.level` attribute."
  def level(%__MODULE__{} = q), do: pipe_expr(q, ".level")

  @doc "Access the `.index` attribute (item index in a list)."
  def item_index(%__MODULE__{} = q), do: pipe_expr(q, ".index")

  @doc "Access the `.ordered` attribute."
  def ordered(%__MODULE__{} = q), do: pipe_expr(q, ".ordered")

  @doc "Access the `.checked` attribute (task list)."
  def checked(%__MODULE__{} = q), do: pipe_expr(q, ".checked")

  @doc "Access the `.column` attribute."
  def column(%__MODULE__{} = q), do: pipe_expr(q, ".column")

  @doc "Access the `.row` attribute."
  def row(%__MODULE__{} = q), do: pipe_expr(q, ".row")

  @doc "Access the `.align` attribute."
  def align(%__MODULE__{} = q), do: pipe_expr(q, ".align")

  @doc "Access the `.name` attribute (MDX element name)."
  def mdx_name(%__MODULE__{} = q), do: pipe_expr(q, ".name")

  @doc "Access a dict property by key (generates `.\"key\"`)."
  def property(%__MODULE__{} = q, key), do: pipe_expr(q, ".\"#{key}\"")

  # ── Markdown attribute mutation ───────────────────────────────────────────

  @doc "Update the node content to `content`."
  def update(%__MODULE__{} = q, content), do: pipe_expr(q, "update(#{inspect(content)})")

  @doc "Get the attribute named `name`."
  def attr(%__MODULE__{} = q, name), do: pipe_expr(q, "attr(#{inspect(name)})")

  @doc "Set the attribute named `name` to `val`."
  def set_attr(%__MODULE__{} = q, name, val),
    do: pipe_expr(q, "set_attr(#{inspect(name)}, #{inspect(val)})")

  @doc "Get the title of a link or image."
  def get_title(%__MODULE__{} = q), do: pipe_expr(q, "get_title")

  @doc "Get the URL of a link or image."
  def get_url(%__MODULE__{} = q), do: pipe_expr(q, "get_url")

  @doc "Set the checked state of a task list item."
  def set_check(%__MODULE__{} = q, val), do: pipe_expr(q, "set_check(#{val})")

  @doc "Set the reference identifier of a link ref or image ref."
  def set_ref(%__MODULE__{} = q, ref), do: pipe_expr(q, "set_ref(#{inspect(ref)})")

  @doc "Set the language of a code block."
  def set_code_block_lang(%__MODULE__{} = q, lang),
    do: pipe_expr(q, "set_code_block_lang(#{inspect(lang)})")

  @doc "Set whether a list is ordered."
  def set_list_ordered(%__MODULE__{} = q, val), do: pipe_expr(q, "set_list_ordered(#{val})")

  # ── Markdown construction ─────────────────────────────────────────────────

  @doc """
  Convert to a fenced code block.

  - `to_code(q)` — no language (`null`)
  - `to_code(q, "elixir")` — with language
  """
  def to_code(%__MODULE__{} = q, lang \\ nil) do
    pipe_expr(q, if(lang, do: "to_code(#{inspect(lang)})", else: "to_code(null)"))
  end

  @doc "Convert to an inline code span."
  def to_code_inline(%__MODULE__{} = q), do: pipe_expr(q, "to_code_inline()")

  @doc "Convert to a heading of the given `depth` (1–6)."
  def to_h(%__MODULE__{} = q, depth), do: pipe_expr(q, "to_h(#{depth})")

  @doc "Convert to a horizontal rule."
  def to_hr(%__MODULE__{} = q), do: pipe_expr(q, "to_hr()")

  @doc """
  Convert to a link node.

  - `to_link(q, url)` — current value becomes the link text
  - `to_link(q, url, text)` — explicit text, empty title
  - `to_link(q, url, text, title)` — explicit text and title
  """
  def to_link(%__MODULE__{} = q, url) do
    pipe_expr(q, "to_link(#{inspect(url)}, \"\")")
  end

  def to_link(%__MODULE__{} = q, url, text) do
    pipe_expr(q, "to_link(#{inspect(url)}, #{inspect(text)}, \"\")")
  end

  def to_link(%__MODULE__{} = q, url, text, link_title) do
    pipe_expr(q, "to_link(#{inspect(url)}, #{inspect(text)}, #{inspect(link_title)})")
  end

  @doc """
  Convert to an image node.

  - `to_image(q, url)` — current value becomes the alt text
  - `to_image(q, url, alt)` — explicit alt, empty title
  - `to_image(q, url, alt, title)` — explicit alt and title
  """
  def to_image(%__MODULE__{} = q, url) do
    pipe_expr(q, "to_image(#{inspect(url)}, \"\")")
  end

  def to_image(%__MODULE__{} = q, url, img_alt) do
    pipe_expr(q, "to_image(#{inspect(url)}, #{inspect(img_alt)}, \"\")")
  end

  def to_image(%__MODULE__{} = q, url, img_alt, img_title) do
    pipe_expr(q, "to_image(#{inspect(url)}, #{inspect(img_alt)}, #{inspect(img_title)})")
  end

  @doc "Convert to a math block."
  def to_math(%__MODULE__{} = q), do: pipe_expr(q, "to_math()")

  @doc "Convert to an inline math span."
  def to_math_inline(%__MODULE__{} = q), do: pipe_expr(q, "to_math_inline()")

  @doc "Convert to a strong (bold) node."
  def to_strong(%__MODULE__{} = q), do: pipe_expr(q, "to_strong()")

  @doc "Convert to an emphasis (italic) node."
  def to_em(%__MODULE__{} = q), do: pipe_expr(q, "to_em()")

  @doc "Convert to a plain Markdown text node."
  def to_md_text(%__MODULE__{} = q), do: pipe_expr(q, "to_md_text()")

  @doc "Convert to a list item at nesting `list_level`."
  def to_md_list(%__MODULE__{} = q, list_level), do: pipe_expr(q, "to_md_list(#{list_level})")

  @doc "Convert to a Markdown element with the given node `node_name`."
  def to_md_name(%__MODULE__{} = q, node_name), do: pipe_expr(q, "to_md_name(#{inspect(node_name)})")

  @doc "Build a table row from the given `cells` list."
  def to_md_table_row(%__MODULE__{} = q, cells) when is_list(cells) do
    cell_str = Enum.map_join(cells, ", ", &inspect/1)
    pipe_expr(q, "to_md_table_row(#{cell_str})")
  end

  @doc "Build a table cell with `content` at row `r`, column `c`."
  def to_md_table_cell(%__MODULE__{} = q, content, r, c),
    do: pipe_expr(q, "to_md_table_cell(#{inspect(content)}, #{r}, #{c})")

  # ── Pipe two Query structs ────────────────────────────────────────────────

  @doc """
  Pipe two queries together.

      Query.h2() |> Query.pipe(Query.to_text())
      # => ".h2 | to_text()"
  """
  def pipe(%__MODULE__{} = q1, %__MODULE__{expr: expr2}), do: pipe_expr(q1, expr2)

  # ── Conversion ────────────────────────────────────────────────────────────

  @doc "Return the raw mq query string."
  def to_query_string(%__MODULE__{expr: expr}), do: expr
end

defimpl String.Chars, for: Mq.Query do
  def to_string(%Mq.Query{expr: expr}), do: expr
end

defimpl Inspect, for: Mq.Query do
  def inspect(%Mq.Query{expr: expr}, _opts), do: "#Mq.Query<#{expr}>"
end
