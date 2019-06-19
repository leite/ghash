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
  def encode lat, lon \\ [], binary \\ false, depth \\ 50
  def encode(0, list, _binary, _depth) when is_list list do
    to_string list
  end

  def encode(bin, list, _binary, _depth) when is_integer(bin) and is_list(list) do
    encode bin >>> 5, [@b32[rem(bin, 0x20)] | list]
  end

  def encode(lat, lon, true, depth) when is_float(lat) and is_float(lon) do
    encode lat, lon, depth, -90.0, 90.0, -180.0, 180.0
  end

  def encode(lat, lon, false, depth) when is_float(lat) and is_float(lon) do
    encode(lat, lon, depth, -90.0, 90.0, -180.0, 180.0) |> encode
  end

  @doc """
  Decode geohash

  ## Examples

      iex> Ghash.decode "6gyf4bf8mk", true
      228644876657266

      iex> Ghash.decode "6gyf4bf8mk", 4
      [-23.5505, -46.6333]

      iex> Ghash.decode 228644876657266
      [-23.550501, -46.633299]

      iex> Ghash.decode "6gyf4bf8mk"
      [-23.550501, -46.633299]

  """
  def decode hash, round \\ 6
  def decode hash, true do
    String.codepoints(hash) |> decode_binary
  end

  def decode hash, round do
    %{sw: [la_min, lo_min], ne: [la_max, lo_max]} = bounds hash

    [Float.round((la_min + la_max) / 2, round), Float.round((lo_min + lo_max) / 2, round)]
  end

  @doc """
  Get geohash bounds

  ## Examples

      iex> Ghash.bounds "6gyf4bf8mk"
      %{
        ne: [-23.550497889518738, -46.63329362869263],
        sw: [-23.550503253936768, -46.63330435752869]
      }

      iex> Ghash.bounds 228644876657266
      %{
        ne: [-23.550497889518738, -46.63329362869263],
        sw: [-23.550503253936768, -46.63330435752869]
      }

  """
  def bounds(hash) when is_bitstring hash do
    {lo_min, lo_max, la_min, la_max} =
      String.codepoints(hash)
      |> bounds(-90.0, 90.0, -180.0, 180.0, true)

    %{sw: [la_min, lo_min], ne: [la_max, lo_max]}
  end

  def bounds(hash) when is_integer hash do
    encode(hash) |> bounds
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

  defp bounds [char], la_min, la_max, lo_min, lo_max, even do
    get_bounds @b32[char], la_min, la_max, lo_min, lo_max, even
  end

  defp bounds [char | tail], la_min, la_max, lo_min, lo_max, even do
    {lo_min, lo_max, la_min, la_max} =
      get_bounds @b32[char], la_min, la_max, lo_min, lo_max, even

    bounds tail, la_min, la_max, lo_min, lo_max, !even
  end

  defp get_bounds char_index, la_min, la_max, lo_min, lo_max, even, n \\ 4 do
    bit = char_index >>> n &&& 1

    {lo_min, lo_max, la_min, la_max} = result = if even do
      mid = (lo_min + lo_max) / 2
      if bit == 1 do
        {mid, lo_max, la_min, la_max}
      else
        {lo_min, mid, la_min, la_max}
      end
    else
      mid = (la_min + la_max) / 2
      if bit == 1 do
        {lo_min, lo_max, mid, la_max}
      else
        {lo_min, lo_max, la_min, mid}
      end
    end

    if n == 0 do
      result
    else
      get_bounds char_index, la_min, la_max, lo_min, lo_max, !even, n - 1
    end
  end
end
