defmodule Argent.Formatting do
  require EEx

  @h Argent

  @type t :: Argent.t
  @type template :: String.t
  @type options :: Keyword.t
  @type format :: String.t

  @doc """
  Creates a display representation of the cash quantity according to a provided
  set of formatting rules.

  ## Examples

      iex> Argent.new(100, "USD") |> Argent.format
      "$100.00"

      iex> Argent.new(100, "BYR") |> Argent.format
      "100,00 Br"

      iex> Argent.new(100, "USD") |> Argent.format(with_code: true)
      "$100.00 USD"

      iex> Argent.new(100, "USD") |> Argent.format(show_sign: :always)
      "+$100.00"

      iex> Argent.new(-100, "USD") |> Argent.format
      "-$100.00"

      iex> Argent.new(100, "USD") |> Argent.format(show_sign: :only_negative)
      "$100.00"

      iex> Argent.new(100, "AUD") |> Argent.format(disambiguate: true)
      "A$100.00"

  """
  @spec format(t, options) :: format
  def format(%@h{fractional: f, currency: c}, opts \\ []) do
    options = Dict.merge(default_options(c), opts)

    if opts[:display_free] && (f == 0.0) do
      is_binary(opts[:display_free]) && opts[:display_free] || "free"
    else
      template = build_prefix(options) <> 
        build_numeric(abs(f / c.subunit_to_unit), options) <>
        build_postfix(options)

      EEx.eval_string(template, assigns: [
        symbol: options[:disambiguate] && c.disambiguate_symbol || options.symbol,
        code: c.iso_code,
        sign: (case {options[:show_sign], f >= 0.0} do
          {:always, true} -> "+"
          {:always, false} -> "-"
          {:only_positive, true} -> "+"
          {:only_negative, false} -> "-"
          _ -> ""
        end)
      ])
    end
  end

  defp build_prefix(opts) do
    sign = "<%= @sign %>"

    symbol = if opts[:symbol_position] == :before do
      "<%= @symbol %>" <> (opts[:pad_symbol] && " " || "")
    else
      ""
    end

    if opts[:sign_position] == :before do
      sign <> symbol
    else
      symbol <> sign
    end
  end

  defp build_postfix(opts) do
    code = "<%= @code %>"

    symbol = if opts[:symbol_position] == :after do
      (opts[:pad_symbol] && " " || "") <> "<%= @symbol %>" 
    else
      ""
    end

    if opts[:with_code], do: " " <> code, else: symbol
  end

  defp default_options(currency) do
    %{
      display_free: false,
      with_code: false,
      compact: false,
      decimals: trunc(Argent.Currency.exponent(currency)),
      symbol: currency.symbol,
      symbol_position: currency.symbol_first && :before || :after,
      south_asian: false,
      pad_symbol: !currency.symbol_first,
      thousands_separator: currency.thousands_separator,
      decimal_mark: currency.decimal_mark,
      show_sign: :only_negative,
      sign_position: :before,
      disambiguate: false
    }
  end

  defp build_numeric(quantity, opts) do
    # Stringerize the floating point number.
    quantity = Float.to_string(quantity, decimals: opts[:decimals])

    # Separate the characteristic and the mantissa.
    [char, mant] = if opts[:decimals] > 0,
      do: String.split(quantity, "."),
      else: [quantity, ""]

    # For every digit in the characteristic followed by exactly three digits, 
    # replace that digit with itself followed by a comma. If we're doing 
    # South Asian formatting, remove the lowest triplet and perform the same
    # substitution for two digits.
    if opts[:south_asian] do
      pairs = String.slice(char, 0..-4)
      triplet = String.slice(char, -3..-1)

      char = Enum.join([
        String.replace(pairs, ~r/\d(?=(?:\d{2})+(?!\d))/, opts[:thousands_separator]),
        triplet
      ], opts[:thousands_separator])

      Enum.join([char, mant], opts[:decimal_mark])
    else
      Enum.join([
        String.replace(char, ~r/\d(?=(?:\d{3})+(?!\d))/, opts[:thousands_separator]), 
        mant
      ], opts[:decimal_mark])
    end
  end
end
