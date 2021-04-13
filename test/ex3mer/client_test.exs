defmodule Ex3mer.ClientTest do
  use ExUnit.Case

  import Mox
  import Ex3mer.ClientTestHelpers

  alias HTTPoison.AsyncResponse

  alias Ex3mer.{Client, Download}

  test "with single chunk" do
    id = make_ref()

    HTTPoisonMock
    |> expect(:request, fn _, _, _, _, _ ->
      {:ok, %AsyncResponse{id: id}}
    end)
    |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

    msg_async_status(id, 200)
    msg_async_headers(id, [{"Content-Length", "10"}])
    msg_async_chunk(id, "helloworld")
    msg_async_end(id)

    chunks =
      download()
      |> Client.stream!(http_client: HTTPoisonMock)
      |> Enum.to_list()

    assert ["helloworld"] = chunks
  end

  describe "stream object successfully" do
    test "with single chunk" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 200)
      msg_async_headers(id, [{"Content-Length", "10"}])
      msg_async_chunk(id, "helloworld")
      msg_async_end(id)

      chunks =
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()

      assert ["helloworld"] = chunks
    end

    test "with multiple chunks" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 200)
      msg_async_headers(id, [{"Content-Length", "12"}])
      msg_async_chunk(id, "foo")
      msg_async_chunk(id, "bar")
      msg_async_chunk(id, "baz")
      msg_async_chunk(id, "coz")
      msg_async_end(id)

      chunks =
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()

      assert ["foo", "bar", "baz", "coz"] = chunks
    end

    test "recover from fail (disconnection)" do
      id_1 = make_ref()
      id_2 = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id_1}}
      end)
      |> expect(:request, fn _, _, _, headers, _ ->
        assert {"Range", "bytes=6-"} = fetch_header(headers, "Range")

        {:ok, %AsyncResponse{id: id_2}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: _id} -> :ok end)

      msg_async_status(id_1, 200)
      msg_async_headers(id_1, [{"Content-Length", "12"}, {"Accept-Ranges", "bytes"}])
      msg_async_chunk(id_1, "foo")
      msg_async_chunk(id_1, "bar")
      msg_async_end(id_1)

      msg_async_status(id_2, 206)
      msg_async_headers(id_2, [{"Content-Length", "6"}, {"Accept-Ranges", "bytes"}])
      msg_async_chunk(id_2, "baz")
      msg_async_chunk(id_2, "coz")
      msg_async_end(id_2)

      chunks =
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()

      assert ["foo", "bar", "baz", "coz"] = chunks
    end

    test "recover from fail (timeout)" do
      id_1 = make_ref()
      id_2 = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id_1}}
      end)
      |> expect(:request, fn _, _, _, headers, _ ->
        assert {"Range", "bytes=6-"} = fetch_header(headers, "Range")

        {:ok, %AsyncResponse{id: id_2}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: _id} -> :ok end)

      msg_async_status(id_1, 200)
      msg_async_headers(id_1, [{"Content-Length", "12"}, {"Accept-Ranges", "bytes"}])
      msg_async_chunk(id_1, "foo")
      msg_async_chunk(id_1, "bar")
      msg_async_error(id_1, {:closed, :timeout})

      msg_async_status(id_2, 206)
      msg_async_headers(id_2, [{"Content-Length", "6"}, {"Accept-Ranges", "bytes"}])
      msg_async_chunk(id_2, "baz")
      msg_async_chunk(id_2, "coz")
      msg_async_end(id_2)

      chunks =
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()

      assert ["foo", "bar", "baz", "coz"] = chunks
    end
  end

  describe "raise failures" do
    test "file not found" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 404)
      msg_async_end(id)

      assert_raise Ex3mer.Error, ~r/Object not found/, fn ->
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()
      end
    end

    test "access denied" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 403)
      msg_async_end(id)

      assert_raise Ex3mer.Error, ~r/Access denied/, fn ->
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()
      end
    end

    test "unexpected status code" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 500)
      msg_async_end(id)

      assert_raise Ex3mer.Error, ~r/Unexpected status code: 500/, fn ->
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()
      end
    end

    test "missing Content-Length header" do
      id = make_ref()

      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ ->
        {:ok, %AsyncResponse{id: id}}
      end)
      |> stub(:stream_next, fn %AsyncResponse{id: ^id} -> :ok end)

      msg_async_status(id, 200)
      msg_async_headers(id, [{"Foo-Bar", "Baz"}])

      assert_raise Ex3mer.Error, ~r/Missing Content-Length header/, fn ->
        download()
        |> Client.stream!(http_client: HTTPoisonMock)
        |> Enum.to_list()
      end
    end

    test "multiple disconnections" do
      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 1}} end)
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 2}} end)
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 3}} end)
      |> stub(:stream_next, fn %AsyncResponse{id: _id} -> :ok end)

      msg_async_status(1, 200)
      msg_async_end(1)
      msg_async_status(2, 200)
      msg_async_end(2)
      msg_async_status(3, 200)
      msg_async_end(3)

      assert_raise Ex3mer.Error,
        ~r/Failed after 2 attempts. Last reason: :end/,
                   fn ->
                     download()
                     |> Client.stream!(http_client: HTTPoisonMock, max_errors: 2)
                     |> Enum.to_list()
                   end
    end

    test "multiple timeouts" do
      HTTPoisonMock
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 1}} end)
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 2}} end)
      |> expect(:request, fn _, _, _, _, _ -> {:ok, %AsyncResponse{id: 3}} end)
      |> stub(:stream_next, fn %AsyncResponse{id: _id} -> :ok end)

      msg_async_status(1, 200)
      msg_async_error(1, {:closed, :timeout})
      msg_async_status(2, 200)
      msg_async_error(2, {:closed, :timeout})
      msg_async_status(3, 200)
      msg_async_error(3, {:closed, :timeout})

      assert_raise Ex3mer.Error,
                   ~r/Failed after 2 attempts. Last reason: {:closed, :timeout}/,
                   fn ->
                     download()
                     |> Client.stream!(http_client: HTTPoisonMock, max_errors: 2)
                     |> Enum.to_list()
                   end
    end
  end

  defp download() do
    %Download{
      http_method: :get,
      url: "http://example.com/file",
      headers: [],
      body: ""
    }
  end
end
