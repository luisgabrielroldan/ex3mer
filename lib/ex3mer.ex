defmodule Ex3mer do
  @moduledoc """
  Ex3mer is a tool for building streams from HTTP resources

  ## Basic operation

  #### Example for S3

  ```
  Ex3mer.S3.download_object("my-bucket", "path/to/object")
  |> Ex3mer.stream!()
  |> Enum.to_list()
  ```

  #### Generic download

  ```
  Ex3mer.Download.from(:get, "http://example.com/path/to/file.zip")
  |> Ex3mer.stream!()
  |> Enum.to_list()
  ```

  `Ex3mer.stream!/2` returns a stream of chunks that will be available as soon they are received from the server.
  """

  defdelegate stream!(opts), to: Ex3mer.Client
end
