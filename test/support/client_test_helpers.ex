defmodule Ex3mer.ClientTestHelpers do
  @moduledoc false

  alias HTTPoison.{
    AsyncChunk,
    AsyncEnd,
    AsyncHeaders,
    AsyncStatus,
    Error
  }

  def msg_async_status(id, code),
    do: send(self(), %AsyncStatus{id: id, code: code})

  def msg_async_headers(id, headers),
    do: send(self(), %AsyncHeaders{id: id, headers: headers})

  def msg_async_chunk(id, chunk),
    do: send(self(), %AsyncChunk{id: id, chunk: chunk})

  def msg_async_end(id),
    do: send(self(), %AsyncEnd{id: id})

  def msg_async_error(id, reason),
    do: send(self(), %Error{id: id, reason: reason})

  def fetch_header(headers, header_name) do
    Enum.find(headers, fn {name, _} -> name == header_name end)
  end
end
