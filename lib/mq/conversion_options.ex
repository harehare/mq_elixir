defmodule Mq.ConversionOptions do
  @moduledoc """
  Options for HTML to Markdown conversion.

  ## Fields

  - `:extract_scripts_as_code_blocks` - Extract `<script>` tags as code blocks
  - `:generate_front_matter` - Generate YAML front matter from meta tags
  - `:use_title_as_h1` - Use `<title>` tag as H1 heading
  """

  @type t :: %__MODULE__{
          extract_scripts_as_code_blocks: boolean(),
          generate_front_matter: boolean(),
          use_title_as_h1: boolean()
        }

  defstruct extract_scripts_as_code_blocks: false,
            generate_front_matter: false,
            use_title_as_h1: false

  @doc """
  Convert ConversionOptions struct to a map for passing to NIF.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = opts) do
    Map.from_struct(opts)
  end
end
