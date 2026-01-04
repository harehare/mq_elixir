defmodule Mq.Native do
  @moduledoc false

  @on_load :load_nifs

  def load_nifs do
    path = :filename.join(:code.priv_dir(:mq), ~c"native/libmq_nif")
    :erlang.load_nif(path, 0)
  end

  @doc false
  def run(_code, _content, _options), do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def html_to_markdown(_content, _options), do: :erlang.nif_error(:nif_not_loaded)
end
