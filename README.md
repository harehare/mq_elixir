# mq-elixir

Elixir bindings for [mq](https://mqlang.org/), a jq-like command-line tool for Markdown processing.

## Features

- Process markdown, MDX, HTML, and plain text
- Full mq query language support
- Multiple input and output format options
- Configurable rendering options
- Fast Rust-powered NIF implementation

## Installation

Add `mq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mq, "~> 0.5.9"}
  ]
end
```

## Requirements

- Elixir >= 1.14
- Erlang/OTP >= 25
- Rust >= 1.70 (for compilation)

## Usage

### Basic Query

```elixir
# Extract all H1 headings
{:ok, result} = Mq.run(".h1", "# Hello\n## World")
IO.inspect(result.values)  # ["# Hello"]
```

### Working with Results

```elixir
{:ok, result} = Mq.run(".h", "# H1\n## H2\n### H3")

# Access values
result.values  # ["# H1", "## H2", "### H3"]
result.text    # "# H1\n## H2\n### H3"

# Enumerate
Enum.each(result, fn heading -> IO.puts(heading) end)
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/mq).

For mq query language syntax, see the [official mq documentation](https://mqlang.org/).

## License

MIT License - see [LICENSE](LICENSE) for details.

