defmodule HashMap do

  def sigil_h string, [] do
    String.split(string)
    |> Stream.with_index
    |> Enum.reduce(%{}, fn {item, index}, acc ->
      Map.put(acc, item, index) |> Map.put(index, item)
    end)
  end
end
