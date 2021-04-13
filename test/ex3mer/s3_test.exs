defmodule Ex3mer.S3Test do
  use ExUnit.Case

  import Ex3mer.ClientTestHelpers

  alias Ex3mer.{Download, S3}

  setup do
    {:ok,
     ex_aws_config: %{
       virtual_host: false,
       host: "s3.amazonaws.com",
       scheme: "https://",
       json_codec: Jason,
       access_key_id: "foo",
       secret_access_key: "bar",
       region: "us-east-1"
     }}
  end

  describe "build download operation" do
    test "contains required headers", %{ex_aws_config: config} do
      assert %Download{
               headers: headers
             } = S3.get_object("my-bucket", "foo/bar", ex_aws_config: config)

      assert fetch_header(headers, "Authorization")
      assert fetch_header(headers, "x-amz-content-sha256")
      assert fetch_header(headers, "x-amz-date")
      assert fetch_header(headers, "host")
    end

    test "with virtual_host=false", %{ex_aws_config: config} do
      assert %Download{
               headers: headers,
               url: "https://s3.amazonaws.com/my-bucket/foo/bar"
             } = S3.get_object("my-bucket", "foo/bar", ex_aws_config: config)

      assert {_, "s3.amazonaws.com"} = fetch_header(headers, "host")
    end

    test "with virtual_host=true", %{ex_aws_config: config} do
      config = %{config | virtual_host: true}

      assert %Download{
               headers: headers,
               url: "https://my-bucket.s3.amazonaws.com/foo/bar"
             } = S3.get_object("my-bucket", "foo/bar", ex_aws_config: config)

      assert {_, "my-bucket.s3.amazonaws.com"} = fetch_header(headers, "host")
    end

    test "expands paths", %{ex_aws_config: config} do
      assert %Download{
               headers: headers,
               url: "https://s3.amazonaws.com/my-bucket/coz"
             } = S3.get_object("my-bucket", "foo/bar/../../coz", ex_aws_config: config)

      assert {_, "s3.amazonaws.com"} = fetch_header(headers, "host")
    end
  end
end
