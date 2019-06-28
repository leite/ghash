defmodule Ghash do
  use Bitwise, only_operators: true
  import HashMap

  @moduledoc """
  Documentation for Ghash.
  """

  @b32  ~h(0 1 2 3 4 5 6 7 8 9 b c d e f g h j k m n p q r s t u v w x y z)

  # 4x8 prxz, nqwy, ...
  @even ~h(p r x z n q w y j m t v h k s u 5 7 e g 4 6 d f 1 3 9 c 0 2 8 b)

  # 8x4 bcfguvyz, 89destwx, ...
  @odd  ~h(b c f g u v y z 8 9 d e s t w x 2 3 6 7 k m q r 0 1 4 5 h j n p)

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
  def decode(hash, true) when is_bitstring hash do
    String.codepoints(hash) |> decode_binary
  end

  def decode(hash, round) when is_bitstring(hash) or is_integer(hash) do
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

  @doc """
  Get range of hashs

  ## Examples

    iex> Ghash.range "6u4-gx"
    [
      "6u4", "6u5", "6uh", "6uj", "6un", "6up",
      "6gf", "6gg", "6gu", "6gv", "6gy", "6gz",
      "6gd", "6ge", "6gs", "6gt", "6gw", "6gx"
    ]

    iex> Ghash.range "7p9", "7pn"
    [
      "7p9", "7pd", "7pe", "7ps", "7pt", "7pw",
      "7p3", "7p6", "7p7", "7pk", "7pm", "7pq",
      "7p1", "7p4", "7p5", "7ph", "7pj", "7pn"
    ]

    iex> Ghash.range "7p9", "pn"
    nil

  """
  def range from_to do
    [from, to] = String.split from_to, "-"
    {first, _} = String.split_at from, String.length(from) - String.length(to)

    range from, "#{first}#{to}"
  end

  def range from, to do
    cond do
      String.length(from) == String.length(to) ->
        get_boundaries(from, to)
        |> range_recusive
        |> List.flatten
        |> Enum.reverse
      true ->
        nil
    end
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

  defp get_boundaries from, to do
    get_boundaries(String.codepoints(from), String.codepoints(to), 8, [])
    |> Enum.reverse
  end

  defp get_boundaries [from], [to], 8, results do
    [calc_boundary(@odd[from], @odd[to], 8) | results]
  end

  defp get_boundaries [from], [to], 4, results do
    [calc_boundary(@even[from], @even[to], 4) | results]
  end

  defp get_boundaries [from | t_from], [to | t_to], 8, results do
    get_boundaries t_from, t_to, 4, [calc_boundary(@odd[from], @odd[to], 8) | results]
  end

  defp get_boundaries [from | t_from], [to | t_to], 4, results do
    get_boundaries t_from, t_to, 8, [calc_boundary(@even[from], @even[to], 4) | results]
  end

  defp calc_boundary from, to, column do
    {rem(from, column) , div(from, column), rem(to, column), div(to, column)}
  end

  defp range_recusive a, b \\ {true, true, true, true}, c \\ true, d \\ ""
  defp range_recusive [pos], limits, true, parent do
    {col_range, row_range} = get_limits pos, limits, 7, 3

    for r <- row_range, c <- col_range, reduce: [] do
      acc -> ["#{parent}#{@odd[(r * 8) + c]}" | acc]
    end
  end

  defp range_recusive [pos], limits, false, parent do
    {col_range, row_range} = get_limits pos, limits, 3, 7

    for r <- row_range, c <- col_range, reduce: [] do
      acc -> ["#{parent}#{@even[(r * 4) + c]}" | acc]
    end
  end

  defp range_recusive [{x, y, xx, yy} = pos | tail], limits, true, parent do
    {col_range, row_range} = get_limits pos, limits, 7, 3

    for r <- row_range, c <- col_range, reduce: [] do
      acc -> [
        range_recusive(
          tail, {x == c, y == r, xx == c, yy == r}, false, "#{parent}#{@odd[(r * 8) + c]}"
        ) | acc
      ]
    end
  end

  defp range_recusive [{x, y, xx, yy} = pos | tail], limits, false, parent do
    {col_range, row_range} = get_limits pos, limits, 3, 7

    for r <- row_range, c <- col_range, reduce: [] do
      acc -> [
        range_recusive(
          tail, {x == c, y == r, xx == c, yy == r}, true, "#{parent}#{@even[(r * 4) + c]}"
        ) | acc
      ]
    end
  end

  defp get_limits {x, y, xx, yy}, {col, row, col_2, row_2}, col_size, row_size do
    {
      (if col, do: x, else: 0)..(if col_2, do: xx, else: col_size),
      (if row, do: y, else: 0)..(if row_2, do: yy, else: row_size)
    }
  end
end
