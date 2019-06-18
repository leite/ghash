defmodule Ghash do
  use Bitwise, only_operators: true

  @moduledoc """
  Documentation for Ghash.
  """

  @b32 %{
    0  => "0", 1  => "1", 2  => "2", 3  => "3", 4  => "4", 5  => "5", 6  => "6", 7  => "7",
    8  => "8", 9  => "9", 10 => "b", 11 => "c", 12 => "d", 13 => "e", 14 => "f", 15 => "g",
    16 => "h", 17 => "j", 18 => "k", 19 => "m", 20 => "n", 21 => "p", 22 => "q", 23 => "r",
    24 => "s", 25 => "t", 26 => "u", 27 => "v", 28 => "w", 29 => "x", 30 => "y", 31 => "z",

    "0" => 0,  "1" => 1,  "2" => 2,  "3" => 3,  "4" => 4,  "5" => 5,  "6" => 6,  "7" => 7,
    "8" => 8,  "9" => 9,  "b" => 10, "c" => 11, "d" => 12, "e" => 13, "f" => 14, "g" => 15,
    "h" => 16, "j" => 17, "k" => 18, "m" => 19, "n" => 20, "p" => 21, "q" => 22, "r" => 23,
    "s" => 24, "t" => 25, "u" => 26, "v" => 27, "w" => 28, "x" => 29, "y" => 30, "z" => 31
  }

  @doc """
  Encode geohash

  ## Examples

      iex> Ghash.encode 228644876657266
      "6gyf4bf8mk"

      iex> Ghash.encode "6gyf4bf8mk"
      228644876657266

  """
  def encode lat, lon \\ 0 do
    if is_bitstring lat do
      String.codepoints(lat) |> encode_binary
    else
      encode_string lat
    end
  end

  defp encode_string integer, string \\ []
  defp encode_string 0, string do
    to_string string
  end

  defp encode_string number, string do
    index = rem number, 0x20

    encode_string number >>> 5, [@b32[index] | string]
  end

  defp encode_binary list, number \\ 0
  defp encode_binary [single], number do
    number ||| @b32[single]
  end

  defp encode_binary [head | tail], number do
    encode_binary tail, number ||| (@b32[head] <<< (length(tail) * 5))
  end
end
