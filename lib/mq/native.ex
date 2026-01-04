defmodule Mq.Native do
  @moduledoc false

  use Rustler,
    otp_app: :mq,
    crate: :mq_nif,
    path: "native/mq_nif"

  @doc false
  def run(_code, _content, _options), do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def html_to_markdown(_content, _options), do: :erlang.nif_error(:nif_not_loaded)
end

