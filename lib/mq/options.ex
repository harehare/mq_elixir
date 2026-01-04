defmodule Mq.Options do
  @moduledoc """
  Configuration options for mq query execution.

  ## Fields

  - `:input_format` - Input format (`:markdown`, `:mdx`, `:text`, `:html`, `:raw`, `:null`)
  - `:list_style` - List marker style (`:dash`, `:plus`, `:star`)
  - `:link_title_style` - Link title quoting (`:double`, `:single`, `:paren`)
  - `:link_url_style` - Link URL wrapping (`:angle`, `:none`)
  """

  @type input_format :: :markdown | :mdx | :text | :html | :raw | :null
  @type list_style :: :dash | :plus | :star
  @type title_surround_style :: :double | :single | :paren
  @type url_surround_style :: :angle | :none

  @type t :: %__MODULE__{
          input_format: input_format() | nil,
          list_style: list_style() | nil,
          link_title_style: title_surround_style() | nil,
          link_url_style: url_surround_style() | nil
        }

  defstruct [
    :input_format,
    :list_style,
    :link_title_style,
    :link_url_style
  ]

  @doc """
  Convert Options struct to a map for passing to NIF.
  Filters out nil values.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = opts) do
    opts
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
