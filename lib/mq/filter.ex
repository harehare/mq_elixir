defmodule Mq.Filter do
  @moduledoc """
  Filter expressions for use inside `select()` and `map()` in mq queries.

  Filters are constructed by calling the functions in this module. They can be
  combined with `and_filter/2`, `or_filter/2`, and `negate/1`, and work
  naturally with the `|>` pipe operator.

  ## Examples

      iex> Mq.Filter.contains("Feature")
      #Mq.Filter<contains("Feature")>

      iex> Mq.Filter.contains("Feature") |> Mq.Filter.and_filter(Mq.Filter.starts_with("##")) |> to_string()
      "contains(\\"Feature\\") and starts_with(\\"##\\")"

      iex> Mq.Filter.all([Mq.Filter.contains("API"), Mq.Filter.ne("## Draft")])
      #Mq.Filter<contains("API") and ne("## Draft")>

  Use filters with `Mq.Query.select/2`:

      iex> alias Mq.{Query, Filter}
      iex> Query.h2() |> Query.select(Filter.contains("Feature")) |> to_string()
      ".h2 | select(contains(\\"Feature\\"))"
  """

  @type t :: %__MODULE__{expr: String.t()}

  defstruct [:expr]

  defp new(expr), do: %__MODULE__{expr: expr}

  # --- String matching ---

  @doc "Match nodes whose text contains `text`."
  def contains(text), do: new("contains(#{qs(text)})")

  @doc "Match nodes whose text starts with `text`."
  def starts_with(text), do: new("starts_with(#{qs(text)})")

  @doc "Match nodes whose text ends with `text`."
  def ends_with(text), do: new("ends_with(#{qs(text)})")

  @doc "Match nodes whose text matches the regex `pattern`."
  def test(pattern), do: new("test(#{qs(pattern)})")

  # --- Regex ---

  @doc "Match nodes whose text matches the regex `pattern`."
  def is_regex_match(pattern), do: new("is_regex_match(#{qs(pattern)})")

  @doc "Match nodes whose text does not match the regex `pattern`."
  def is_not_regex_match(pattern), do: new("is_not_regex_match(#{qs(pattern)})")

  # --- Comparison ---

  @doc "Match nodes equal to `value`."
  def eq(value), do: new("eq(#{qv(value)})")

  @doc "Match nodes not equal to `value`."
  def ne(value), do: new("ne(#{qv(value)})")

  @doc "Match nodes greater than `value`."
  def gt(value), do: new("gt(#{qv(value)})")

  @doc "Match nodes greater than or equal to `value`."
  def gte(value), do: new("gte(#{qv(value)})")

  @doc "Match nodes less than `value`."
  def lt(value), do: new("lt(#{qv(value)})")

  @doc "Match nodes less than or equal to `value`."
  def lte(value), do: new("lte(#{qv(value)})")

  # --- Type checks ---

  @doc "Match MDX nodes."
  def is_mdx(), do: new("is_mdx()")

  @doc "Match nodes with no value (none/null)."
  def is_none(), do: new("is_none()")

  @doc "Match nodes whose numeric value is NaN."
  def is_nan(), do: new("is_nan()")

  @doc "Filter by the node type string."
  def type(), do: new("type")

  # --- Value transforms usable in filter context ---

  @doc "The length of the current value."
  def length(), do: new("length")

  @doc "Lowercase the current value (ASCII only)."
  def ascii_downcase(), do: new("ascii_downcase()")

  @doc "Uppercase the current value (ASCII only)."
  def ascii_upcase(), do: new("ascii_upcase()")

  @doc "Trim whitespace from the current value."
  def trim(), do: new("trim()")

  @doc "Match empty nodes."
  def empty(), do: new("empty")

  @doc "Add/concatenate the current value."
  def add(), do: new("add")

  # --- Boolean combinators ---

  @doc """
  Combine two filters with boolean AND (`&&`).

  Works naturally with `|>`:

      Filter.contains("API") |> Filter.and_filter(Filter.ne("## Draft"))
  """
  def and_filter(%__MODULE__{expr: a}, %__MODULE__{expr: b}), do: new("#{a} && #{b}")

  @doc """
  Combine two filters with boolean OR.

  Works naturally with `|>`:

      Filter.contains("A") |> Filter.or_filter(Filter.contains("B"))
  """
  def or_filter(%__MODULE__{expr: a}, %__MODULE__{expr: b}), do: new("#{a} || #{b}")

  @doc """
  Combine a list of filters with AND (all must match).

      Filter.all([Filter.contains("API"), Filter.ne("## Draft"), Filter.starts_with("## ")])
  """
  def all([single]), do: single

  def all([head | rest]) do
    Enum.reduce(rest, head, &and_filter(&2, &1))
  end

  @doc """
  Combine a list of filters with OR (any must match).

      Filter.any([Filter.contains("A"), Filter.contains("B")])
  """
  def any([single]), do: single

  def any([head | rest]) do
    Enum.reduce(rest, head, &or_filter(&2, &1))
  end

  @doc """
  Negate a filter with `not(...)`.

      Filter.negate(Filter.contains("draft"))
      # => not(contains("draft"))
  """
  def negate(%__MODULE__{expr: expr}), do: new("not(#{expr})")

  @doc "Return the raw filter expression string."
  def to_filter_string(%__MODULE__{expr: expr}), do: expr

  # Inspect string: wraps the value in double quotes.
  defp qs(text), do: inspect(text)

  # Inspect value: strings get quotes, numbers/booleans are bare.
  defp qv(value) when is_binary(value), do: inspect(value)
  defp qv(value), do: to_string(value)
end

defimpl String.Chars, for: Mq.Filter do
  def to_string(%Mq.Filter{expr: expr}), do: expr
end

defimpl Inspect, for: Mq.Filter do
  def inspect(%Mq.Filter{expr: expr}, _opts), do: "#Mq.Filter<#{expr}>"
end
