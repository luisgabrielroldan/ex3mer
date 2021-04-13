defmodule Ex3mer.Download do
  @moduledoc """
  Represents a download operation
  """

  @type method :: :get | :post | :put | :patch | :delete | :options | :head
  @type header :: {binary(), binary()}

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

  @spec from(method(), binary(), binary(), [header()]) :: t()
  def from(method, url, body \\ "", headers \\ []) do
    %__MODULE__{
      body: body,
      headers: headers,
      http_method: method,
      url: url
    }
  end
end
