# mq_elixir

Elixir bindings for [mq](https://mqlang.org/), a jq-like command-line tool for Markdown processing.

## Features

- Process markdown, MDX, HTML, and plain text
- Full mq query language support
- Programmatic query builder with Elixir pipe operator
- Multiple input and output format options
- Configurable rendering options
- Fast Rust-powered NIF implementation

## Installation

Add `mq_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mq_elixir, "~> 0.1.0"}
  ]
end
```

## Usage

### Raw Query String

```elixir
# Extract all H1 headings
{:ok, result} = Mq.run(".h1", "# Hello\n## World")
IO.inspect(result.values)  # ["# Hello"]

# Filter with select
{:ok, result} = Mq.run(".h2 | select(contains(\"Feature\"))", content)
```

### Query Builder

Build queries programmatically using `Mq` functions and the `|>` pipe operator.

```elixir
# Selectors and transformations chain naturally
{:ok, result} =
  Mq.h2()
  |> Mq.select(Mq.Filter.contains("Feature"))
  |> Mq.to_text()
  |> Mq.run(content)
```

#### Selectors

```elixir
Mq.h1()          # .h1
Mq.h2()          # .h2
Mq.code()        # .code
Mq.link()        # .link
Mq.list()        # .[]
Mq.list_at(0)    # .[0]
Mq.paragraph()   # .p
Mq.task()        # .task
Mq.todo()        # .todo
Mq.done()        # .done
# ... and more (heading, image, blockquote, table, etc.)
```

#### Attribute Access

Attribute selectors work as both standalone queries and as chained operations:

```elixir
# Standalone
Mq.url()   # ".url"
Mq.lang()  # ".lang"

# Chained — access attributes of selected nodes
Mq.link() |> Mq.url()   # ".link | .url"
Mq.code() |> Mq.lang()  # ".code | .lang"
```

#### Filters

`Mq.Filter` provides composable filter expressions for `select` and `map`:

```elixir
alias Mq.Filter

# Basic filters
Filter.contains("Feature")
Filter.starts_with("##")
Filter.ends_with("Guide")
Filter.eq("value")
Filter.gt(5)

# Combine with |>
Filter.contains("API")
|> Filter.and_filter(Filter.negate(Filter.contains("Internal")))

# Combine a list
Filter.all([Filter.contains("A"), Filter.contains("B"), Filter.ne("## Draft")])
Filter.any([Filter.contains("Alpha"), Filter.contains("Beta")])

# Negate
Filter.negate(Filter.contains("draft"))
```

#### Chaining Operations

```elixir
Mq.h2()
|> Mq.select(Mq.Filter.contains("API"))
|> Mq.to_text()
|> Mq.downcase()
|> Mq.run(content)
```

Available transforms include: `to_text`, `to_markdown`, `to_html`, `downcase`, `upcase`,
`trim`, `split`, `join`, `limit`, `nth`, `reverse`, `sort`, `uniq`, and many more.

### Working with Results

```elixir
{:ok, result} = Mq.run(".h", "# H1\n## H2\n### H3")

# Access values
result.values  # ["# H1", "## H2", "### H3"]
result.text    # "# H1\n## H2\n### H3"

# Enumerate
Enum.each(result, fn heading -> IO.puts(heading) end)

# Convert to string
to_string(result)  # "# H1\n## H2\n### H3"
```

### Input Formats

```elixir
options = %Mq.Options{input_format: :text}
{:ok, result} = Mq.run("select(contains(\"needle\"))", content, options)
```

Supported formats: `:markdown` (default), `:mdx`, `:html`, `:text`, `:raw`, `:null`

### HTML to Markdown

```elixir
{:ok, markdown} = Mq.html_to_markdown("<h1>Hello</h1><p>World</p>")
# => "# Hello\n\nWorld"

opts = %Mq.ConversionOptions{use_title_as_h1: true}
{:ok, markdown} = Mq.html_to_markdown(html, opts)
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/mq_elixir).

For mq query language syntax, see the [official mq documentation](https://mqlang.org/).

## License

MIT License
