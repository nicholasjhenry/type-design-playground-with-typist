defmodule Maybe do
  use Typist

  deftype({:some, any} | :none)

  def some(value), do: {:some, value}
  def none, do: :none
end
