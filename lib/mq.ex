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

      # Basic heading extraction
      {:ok, result} = Mq.run(".h1", "# Hello\\n## World")
      IO.inspect(result.values)  # ["# Hello"]

      # With options
      options = %Mq.Options{input_format: :markdown}
      {:ok, result} = Mq.run(".h2", markdown_content, options)

      # HTML to Markdown conversion
      {:ok, markdown} = Mq.html_to_markdown("<h1>Hello</h1>")
  """

  alias Mq.{Native, Options, ConversionOptions, Result}

  @doc """
  Run an mq query on the provided content.

  ## Parameters

  - `code` - The mq query string
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
  """
  @spec run(String.t(), String.t(), Options.t() | nil) ::
          {:ok, Result.t()} | {:error, String.t()}
  def run(code, content, options \\ nil) do
    opts = options || %Options{}

    case Native.run(code, content, Options.to_map(opts)) do
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
      iex> {:ok, _markdown} = Mq.html_to_markdown(html_content, opts)
      {:ok, _markdown}
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
end
