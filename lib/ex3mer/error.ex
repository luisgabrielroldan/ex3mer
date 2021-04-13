defmodule Ex3mer.Error do
  defexception reason: nil

  @type t :: %__MODULE__{reason: any}

  @doc """
  """
  def message(%__MODULE__{reason: reason}), do: inspect(reason)
end
