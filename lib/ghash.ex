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

      iex> Ghash.encode -23.5505, -46.6333
      "6gyf4bf8mk"

      iex> Ghash.encode -23.5505, -46.6333, true
      228644876657266

  """
  def encode lat, lon \\ 0, binary \\ false, depth \\ 50 do
    cond do
      is_integer lat ->
        encode_string lat
      is_float(lon) and binary ->
        encode lat, lon, depth, -90.0, 90.0, -180.0, 180.0
      is_float(lon) and !binary ->
        encode(lat, lon, depth, -90.0, 90.0, -180.0, 180.0) |> encode_string
      true ->
        nil
    end
  end

  @doc """
  Decode geohash

  ## Examples

      iex> Ghash.decode "6gyf4bf8mk"
      228644876657266

  """
  def decode hash do
    String.codepoints(hash) |> decode_binary
  end

  defp encode_string integer, string \\ []
  defp encode_string 0, string do
    to_string string
  end

  defp encode_string number, string do
    index = rem number, 0x20

    encode_string number >>> 5, [@b32[index] | string]
  end

  defp decode_binary list, number \\ 0
  defp decode_binary [single], number do
    number ||| @b32[single]
  end

  defp decode_binary [head | tail], number do
    decode_binary tail, number ||| (@b32[head] <<< (length(tail) * 5))
  end

  defp encode(
    lat, lon, depth, la_min, la_max, lo_min, lo_max, total \\ 0, combined \\ 0, even \\ false
  ) do
    {lo_min, lo_max, la_min, la_max, combined} = if even do
      if lat > (mid = (la_min + la_max) / 2) do
        {lo_min, lo_max, mid, la_max, combined * 2 + 1}
      else
        {lo_min, lo_max, la_min, mid, combined * 2}
      end
    else
      if lon > (mid = (lo_min + lo_max) / 2) do
        {mid, lo_max, la_min, la_max, combined * 2 + 1}
      else
        {lo_min, mid, la_min, la_max, combined * 2}
      end
    end

    if (total = total + 1) < depth do
      encode lat, lon, depth, la_min, la_max, lo_min, lo_max, total, combined, !even
    else
      combined
    end
  end
end
