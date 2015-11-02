defmodule Argent.Formatting do
  @h Argent
  @type t :: Argent.t

  @spec format(t) :: String.t
  def format(%@h{fractional: f, currency: c}) do
    [char, mant] = Float.to_string(f * c.subunit_to_unit, decimals: 2)
      |> String.split(".")

    numeric = Enum.join([
      String.replace(~r/\B(?=(\d{3})+(?!\d))/, c.thousands_separator), mant
    ], c.decimal_mark)

    c.symbol <> numeric
  end

  def format(%@h{currency: c}=argent, opts \\ []) do
    numeric = build_numeric(argent, opts)
  end

  def format(%@h{fractional: f, currency: c}, opts \\ []) do
  end

  defp build_structure(%@h{currency: c}, opts \\ []) do
  end

  defp build_numeric(%@h{fractional: f, currency: c}, opts \\ []) do
    [char, mant] = Float.to_string(f * c.subunit_to_unit, decimals: 2)
      |> String.split(".")

    if opts[:south_asian] do
      pairs = String.slice(char, 0..-4)
      triplet = String.slice(char, -3..-1)

      char = Enum.join([
        String.replace(pairs, ~r/\B(?=(\d{2})+(?!\d))/, c.thousands_separator),
        triplet
      ], c.thousands_separator)

      Enum.join([char, mant], c.decimal_mark)
    else
      Enum.join([
        String.replace(~r/\B(?=(\d{3})+(?!\d))/, c.thousands_separator), mant
      ], c.decimal_mark)
    end
  end
end
