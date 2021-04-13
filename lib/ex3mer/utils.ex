defmodule Ex3mer.Utils do
  @moduledoc false

  def abs_path(<<"/", _rest::binary>> = path), do: path
  def abs_path(path), do: "/#{expand_dot(path)}"

  def expand_path(path) do
    path |> abs_path() |> expand_dot()
  end

  # Based on Elixir v1.11.4 Path.expand_dot/2
  defp expand_dot(<<"/", rest::binary>>), do: "/" <> do_expand_dot(rest)
  defp expand_dot(path), do: do_expand_dot(path)

  defp do_expand_dot(path), do: do_expand_dot(:binary.split(path, "/", [:global]), [])
  defp do_expand_dot([".." | t], [_, _ | acc]), do: do_expand_dot(t, acc)
  defp do_expand_dot([".." | t], []), do: do_expand_dot(t, [])
  defp do_expand_dot(["." | t], acc), do: do_expand_dot(t, acc)
  defp do_expand_dot([h | t], acc), do: do_expand_dot(t, ["/", h | acc])
  defp do_expand_dot([], []), do: ""
  defp do_expand_dot([], ["/" | acc]), do: IO.iodata_to_binary(:lists.reverse(acc))
end
