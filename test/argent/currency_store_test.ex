defmodule Argent.CurrencyStoreTest do
  use ExUnit.Case, async: true
  alias Argent.CurrencyStore

  setup do
    {:ok, store} = CurrencyStore.start_link
    {:ok, store: store}
  end

  test "bootstraps common currencies", %{store: store} do
    {:ok, usd} = CurrencyStore.lookup("USD")
    assert usd.name == "United States Dollar"
    assert usd.symbol == "$"
  end

  test "registers new currencies", %{store: store} do
    sim = CurrencyStore.register("SIM", %{
      name: "Simoleons",
      iso_code: "SIM",
      symbol: <<167 :: utf8>>
    })

    {:ok, result} = CurrencyStore.lookup("SIM")

    assert sim.name == "Simoleons"
    assert result == sim
  end
end
