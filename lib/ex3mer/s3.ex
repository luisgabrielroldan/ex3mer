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

  @type get_object_opts :: {:ex_aws_config, ExAWsConfig.t()}

  @doc "Get an object from a bucket"
  @spec get_object(binary, binary, [get_object_opts]) :: Download.t()
  def get_object(bucket, path, opts \\ nil) do
    ex_aws_config = opts[:ex_aws_config] || ExAWsConfig.new(@service)

    {url, ex_aws_config} = build_object_url(bucket, path, ex_aws_config)

    headers = build_headers(:get, url, ex_aws_config, @empty_body)

    %Download{
      url: url,
      headers: headers,
      http_method: :get,
      body: @empty_body
    }
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
