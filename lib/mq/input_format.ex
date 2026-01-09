defmodule Mq.InputFormat do
  @moduledoc """
  Input format constants for mq queries.

  ## Available Formats

  - `:markdown` - Standard Markdown (default)
  - `:mdx` - Markdown with JSX
  - `:html` - HTML content
  - `:text` - Plain text (line-by-line processing)
  - `:raw` - Raw string input
  - `:null` - Null/empty input
  """

  @type t :: :markdown | :mdx | :html | :text | :raw | :null

  @doc """
  List all available input formats.
  """
  @spec all() :: [t(), ...]
  def all, do: [:markdown, :mdx, :html, :text, :raw, :null]

  @doc """
  Validate an input format.
  """
  @spec valid?(atom()) :: boolean()
  def valid?(format), do: format in all()
end
