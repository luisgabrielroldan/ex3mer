defmodule Ex3mer do
  @moduledoc """
  Ex3mer is a library for building streams from HTTP resources
  """

  alias Ex3mer.{Download, Error}

  @doc """
  Builds a download
  """
  @spec download(Download.method(), binary(), binary(), Download.headers()) :: Download.t()
  def download(method, url, body \\ "", headers \\ []) do
    %Download{
      body: body,
      headers: headers,
      http_method: method,
      url: url
    }
  end

  @doc """
  Returns a stream of events.
  """
  @spec stream!(Download.t(), Download.stream_opts()) :: Enumerable.t()
  def stream!(%Download{} = download, opts \\ []) do
    Download.stream!(download, opts)
  end

  @doc """
  Returns a stream of chunks. Status non 2XX statues are raised as errors.
  """
  @spec stream_data!(Download.t(), Download.stream_opts()) :: Enumerable.t()
  def stream_data!(%Download{} = download, opts \\ []) do
    download
    |> Download.stream!(opts)
    |> Stream.flat_map(&fn_map/1)
  end

  def fn_map({:status, code}) when 199 < code and code < 300,
    do: []

  def fn_map({:status, code}),
    do: raise(%Error{reason: {:status, code}})

  def fn_map({:headers, _}),
    do: []

  def fn_map({:chunk, chunk}),
    do: [chunk]
end
