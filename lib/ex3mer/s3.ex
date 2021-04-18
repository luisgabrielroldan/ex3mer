defmodule Ex3mer.S3 do
  @moduledoc """
  Ex3mer S3 operations
  """

  alias ExAws.{
    Auth,
    Request
  }

  alias ExAws.Config, as: ExAWsConfig
  alias Ex3mer.{Download, Utils}

  @empty_body ""
  @service :s3

  @get_object_params [:version_id]

  @type get_object_opts :: {:ex_aws_config, ExAWsConfig.t()} | {:version_id, binary()}

  @spec get_object(binary, binary, [get_object_opts]) :: Download.t()
  def get_object(bucket, path, opts \\ []) do
    ex_aws_config = opts[:ex_aws_config] || ExAWsConfig.new(@service)

    path = set_params(path, opts)

    {url, ex_aws_config} = build_object_url(bucket, path, ex_aws_config)

    headers = build_headers(:get, url, ex_aws_config, @empty_body)

    %Download{
      url: url,
      headers: headers,
      http_method: :get,
      body: @empty_body
    }
  end

  defp set_params(url, opts) do
    case Keyword.take(opts, @get_object_params) do
      [] ->
        url

      params ->
        query = params |> Enum.into(%{}) |> URI.encode_query()

        "#{url}?#{query}"
    end
  end

  defp build_headers(method, url, ex_aws_config, body) do
    {:ok, headers} = Auth.headers(method, url, :s3, ex_aws_config, [], body)

    headers
    |> put_content_sha(body)
    |> put_content_length_header(body, method)
  end

  defp put_content_length_header(headers, "", :get), do: headers

  defp put_content_length_header(headers, body, _method) do
    [{"Content-Length", byte_size(body) |> Integer.to_string()} | headers]
  end

  defp build_object_url(bucket, path, %{virtual_host: true, host: base_host} = config) do
    vhost = "#{bucket}.#{base_host}"
    path = Utils.expand_path(path)
    url = "#{config.scheme}#{bucket}.#{base_host}#{path}" |> Request.Url.sanitize(@service)

    {url, %{config | host: vhost}}
  end

  defp build_object_url(bucket, path, %{host: host} = config) do
    path = Utils.expand_path(path)
    url = "#{config.scheme}#{host}/#{bucket}#{path}" |> Request.Url.sanitize(@service)

    {url, config}
  end

  defp put_content_sha(headers, body) do
    body_hash = Auth.Utils.hash_sha256(body)
    [{"x-amz-content-sha256", body_hash} | headers]
  end
end
