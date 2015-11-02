defmodule ArgentTest do
  use ExUnit.Case
  doctest Argent

  setup do
    :application.stop(:argent)
    :ok = :application.start(:argent)
  end

  test "instantiate amounts of common currency" do
    cash = Argent.new(1.200, "USD")
    curr = Argent.Currency.find("USD")
    assert cash.currency == curr
  end

  test "instantiate amounts of custom currency" do
    curr = Argent.Currency.register(%{iso_code: "SIM"})
    cash = Argent.new(300, "SIM")

    assert cash.currency == curr
  end

  test "instances normalize amounts to fractional" do
    cash_usd = Argent.new(300.67, "USD")
    cash_kwd = Argent.new(300.67, "KWD")

    assert cash_usd.fractional == 30067
    assert cash_kwd.fractional == 300670
  end

  test "converting an instance to another currency" do
    Argent.Exchange.set_rate("USD", "EUR", 1.5)

    conv = Argent.new(2.00, "USD") |> Argent.convert_to("EUR")

    assert conv.fractional == 300.0
    assert conv.currency == Argent.Currency.find("EUR")
  end

end
