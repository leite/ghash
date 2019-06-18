defmodule Ghash do
  use Bitwise, only_operators: true

  @moduledoc """
  Documentation for Ghash.
  """

  @b32 %{
    0  => "0", 1  => "1", 2  => "2", 3  => "3", 4  => "4", 5  => "5", 6  => "6", 7  => "7",
    8  => "8", 9  => "9", 10 => "b", 11 => "c", 12 => "d", 13 => "e", 14 => "f", 15 => "g",
    16 => "h", 17 => "j", 18 => "k", 19 => "m", 20 => "n", 21 => "p", 22 => "q", 23 => "r",
    24 => "s", 25 => "t", 26 => "u", 27 => "v", 28 => "w", 29 => "x", 30 => "y", 31 => "z"
  }
  

  @doc """
  Encode geohash

  ## Examples

      iex> Ghash.encode 228644876657266
      "6gyf4bf8mk"

  """
  def encode lat, lon \\ 0 do
    encode_string lat
  end

  defp encode_string integer, string \\ []
  defp encode_string 0, string do
    to_string string
  end

  defp encode_string number, string do
    index = rem number, 0x20

    encode_string number >>> 5, [@b32[index] | string]
  end
end
