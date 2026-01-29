defmodule Mq.Result do
  @moduledoc """
  Result of an mq query execution.

  ## Fields

  - `:values` - List of result values (strings)
  - `:text` - All values joined by newlines
  """

  @type t :: %__MODULE__{
          values: [String.t()],
          text: String.t()
        }

  defstruct values: [], text: ""

  @doc """
  Create a Result from a map returned by the NIF.
  """
  @spec from_map(map()) :: t()
  def from_map(%{values: values, text: text}) do
    %__MODULE__{values: values, text: text}
  end

  @doc """
  Get the number of values in the result.
  """
  @spec length(t()) :: non_neg_integer()
  def length(%__MODULE__{values: values}), do: Kernel.length(values)

  @doc """
  Check if the result is empty.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{values: values}), do: values == []
end

defimpl Enumerable, for: Mq.Result do
  def count(result), do: {:ok, Mq.Result.length(result)}

  def member?(result, value) do
    {:ok, value in result.values}
  end

  def reduce(%Mq.Result{values: values}, acc, fun) do
    Enum.reduce(values, acc, fun)
  end

  def slice(%Mq.Result{values: values}) do
    size = Kernel.length(values)

    {:ok, size,
     fn start, length, step -> values |> Enum.slice(start, length) |> Enum.take_every(step) end}
  end
end

defimpl String.Chars, for: Mq.Result do
  def to_string(result), do: result.text
end
