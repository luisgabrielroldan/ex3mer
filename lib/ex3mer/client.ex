defmodule Ex3mer.Client do
  @moduledoc false

  alias HTTPoison.Error, as: HTTPoisonError

  alias HTTPoison.{
    AsyncChunk,
    AsyncEnd,
    AsyncHeaders,
    AsyncResponse,
    AsyncStatus
  }

  alias Ex3mer.{
    Download,
    Error
  }

  @type stream_opt ::
          {:max_errors, non_neg_integer()}
          | {:http_client, module()}

  @spec stream!(Download.t(), [stream_opt]) :: Enumerable.t()
  def stream!(%Download{} = download, opts \\ nil) do
    state = build_state(download, opts)

    Stream.resource(
      fn -> begin_async_request(state) end,
      &stream_res_next/1,
      &stream_res_end/1
    )
  end

  defp build_state(download, opts) do
    %{
      code: nil,
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
      %AsyncStatus{id: ^id, code: code} when code in [200, 206] ->
        http_client.stream_next(resp)

        {[], %{state | code: code}}

      %AsyncStatus{id: ^id, code: 404} ->
        raise %Error{reason: "Object not found"}

      %AsyncStatus{id: ^id, code: 403} ->
        raise %Error{reason: "Access denied"}

      %AsyncStatus{id: ^id, code: code} ->
        raise %Error{reason: "Unexpected status code: #{code}"}

      %AsyncHeaders{id: ^id, headers: headers} ->
        new_state =
          %{state | resp_headers: headers}
          |> maybe_store_total_bytes(headers)

        http_client.stream_next(resp)

        {[], new_state}

      %AsyncChunk{id: ^id, chunk: chunk} ->
        http_client.stream_next(resp)

        new_state = %{state | received_bytes: state.received_bytes + byte_size(chunk)}

        {[chunk], new_state}

      %AsyncEnd{id: ^id} ->
        handle_async_end_or_timeout(state, :end)

      %HTTPoisonError{id: ^id, reason: reason} ->
        handle_async_end_or_timeout(state, reason)
    end
  end

  defp handle_async_end_or_timeout(
         %{
           resp: %{id: id},
           config: %{max_errors: max_errors},
           errors_count: error_count
         } = state,
         reason
       ) do
    :hackney.stop_async(id)

    cond do
      state.received_bytes == state.total_bytes ->
        {:halt, state}

      state.received_bytes < state.total_bytes and error_count < max_errors ->
        new_state =
          %{state | errors_count: state.errors_count + 1}
          |> begin_async_request()

        {[], new_state}

      state.received_bytes < state.total_bytes ->
        raise %Error{
          reason: "Failed after #{state.errors_count} attempts. Last reason: #{inspect(reason)}"
        }

      true ->
        raise %Error{reason: "Extra data received"}
    end
  end

  defp stream_res_end(%{resp: %{id: id}}) do
    :hackney.stop_async(id)
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

  defp maybe_store_total_bytes(%{code: 200, received_bytes: 0} = state, headers),
    do: %{state | total_bytes: fetch_content_length!(headers)}

  defp maybe_store_total_bytes(state, _headers),
    do: state

  defp fetch_content_length!([]),
    do: raise(%Error{reason: "Missing Content-Length header"})

  defp fetch_content_length!([{"Content-Length", val} | _headers]),
    do: String.to_integer(val)

  defp fetch_content_length!([_ | headers]),
    do: fetch_content_length!(headers)

  defp server_support_bytes_ranges?(headers) when is_list(headers) do
    case fetch_header(headers, "Accept-Ranges") do
      "bytes" -> true
      _other -> false
    end
  end

  defp fetch_header([], _name),
    do: nil

  defp fetch_header([{name, value} | _headers], name),
    do: value

  defp fetch_header([_ | headers], name),
    do: fetch_header(headers, name)
end
