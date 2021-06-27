defmodule Ex3mer.Download do
  @moduledoc """
  Download
  """

  alias HTTPoison.Error, as: HTTPoisonError

  alias HTTPoison.{
    AsyncChunk,
    AsyncEnd,
    AsyncHeaders,
    AsyncResponse,
    AsyncStatus
  }

  alias Ex3mer.Error

  @type stream_opt ::
          {:max_errors, non_neg_integer()}
          | {:http_client, module()}

  @type stream_opts :: [stream_opt]

  @type header :: {binary(), binary()}

  @type headers :: [header]

  @type event ::
          {:status, non_neg_integer()}
          | {:headers, [header]}
          | {:chunk, binary()}

  @type method :: :get | :post | :put | :patch | :delete | :options | :head

  @type t :: %__MODULE__{
          body: binary(),
          headers: [header()],
          http_method: method(),
          url: binary()
        }

  defstruct body: nil,
            headers: nil,
            http_method: nil,
            url: nil

  @spec stream!(t(), [stream_opt]) :: Enumerable.t()
  def stream!(%__MODULE__{} = download, opts) do
    state = build_state(download, opts)

    Stream.resource(
      fn -> begin_async_request(state) end,
      &stream_res_next/1,
      &stream_res_end/1
    )
  end

  defp build_state(download, opts) do
    %{
      last_code: nil,
      received_bytes: 0,
      total_bytes: nil,
      resp: nil,
      resp_headers: nil,
      errors_count: 0,
      config: %{
        max_errors: opts[:max_errors] || 10,
        http_client: opts[:http_client] || HTTPoison
      },
      download: download
    }
  end

  defp stream_res_next(%{resp: %{id: id} = resp} = state) do
    %{config: %{http_client: http_client}} = state

    receive do
      %AsyncStatus{id: ^id, code: last_code} ->
        http_client.stream_next(resp)
        new_state = %{state | last_code: last_code}

        if state.received_bytes == 0 do
          {[{:status, last_code}], new_state}
        else
          {[], new_state}
        end

      %AsyncHeaders{id: ^id, headers: headers} ->
        new_state =
          %{state | resp_headers: headers}
          |> maybe_store_total_bytes(headers)

        http_client.stream_next(resp)

        if state.received_bytes == 0 do
          {[{:headers, headers}], new_state}
        else
          {[], new_state}
        end

      %AsyncChunk{id: ^id, chunk: chunk} ->
        http_client.stream_next(resp)

        new_state = %{state | received_bytes: state.received_bytes + byte_size(chunk)}

        {[{:chunk, chunk}], new_state}

      %AsyncEnd{id: ^id} ->
        handle_async_end(state)

      %HTTPoisonError{id: ^id, reason: reason} ->
        handle_async_error(state, reason)
    end
  end

  defp handle_async_end(
         %{
           resp: %{id: id},
           config: %{max_errors: max_errors},
           errors_count: error_count
         } = state
       ) do
    _ = :hackney.stop_async(id)

    cond do
      is_nil(state.total_bytes) ->
        {:halt, state}

      state.received_bytes < state.total_bytes and error_count < max_errors ->
        new_state =
          %{state | errors_count: state.errors_count + 1}
          |> begin_async_request()

        {[], new_state}

      state.received_bytes < state.total_bytes ->
        raise %Error{reason: :closed}

      true ->
        {:halt, state}
    end
  end

  defp handle_async_error(
         %{
           resp: %{id: id},
           config: %{max_errors: max_errors},
           errors_count: error_count
         } = state,
         reason
       ) do
    _ = :hackney.stop_async(id)

    cond do
      error_count < max_errors ->
        new_state =
          %{state | errors_count: state.errors_count + 1}
          |> begin_async_request()

        {[], new_state}

      true ->
        raise %Error{reason: reason}
    end
  end

  defp stream_res_end(%{resp: %{id: id}}) do
    _ = :hackney.stop_async(id)

    flush_messages(id)
  end

  defp begin_async_request(%{download: download} = state) do
    headers = get_request_headers(state)

    case state.config.http_client.request(
           download.http_method,
           download.url,
           download.body,
           headers,
           stream_to: self(),
           async: :once
         ) do
      {:ok, %AsyncResponse{} = resp} ->
        %{state | resp: resp}

      {:error, %HTTPoisonError{reason: reason}} ->
        raise %Error{reason: reason}
    end
  end

  defp get_request_headers(%{download: %{headers: headers}, received_bytes: 0}),
    do: headers

  defp get_request_headers(%{
         download: %{
           headers: headers
         },
         resp_headers: resp_headers,
         received_bytes: received_bytes
       }) do
    if not server_support_bytes_ranges?(resp_headers) do
      raise(%Error{reason: "Server doesn't support bytes ranges. Can't recover from error"})
    end

    [{"Range", "bytes=#{received_bytes}-"} | headers]
  end

  # The content length is obtained from the first request
  defp maybe_store_total_bytes(%{received_bytes: 0} = state, headers) do
    case fetch_header(headers, "Content-Length") do
      nil ->
        state

      length ->
        %{state | total_bytes: String.to_integer(length)}
    end
  end

  defp maybe_store_total_bytes(state, _headers),
    do: state

  defp server_support_bytes_ranges?(headers) when is_list(headers) do
    case fetch_header(headers, "Accept-Ranges") do
      "bytes" -> true
      _other -> false
    end
  end

  defp flush_messages(id) do
    receive do
      %{id: ^id} ->
        flush_messages(id)
    after
      0 ->
        :ok
    end
  end

  defp fetch_header([], _name),
    do: nil

  defp fetch_header([{name, value} | _headers], name),
    do: value

  defp fetch_header([_ | headers], name),
    do: fetch_header(headers, name)
end
