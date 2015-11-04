defmodule Argent do
  @moduledoc """
  Defines a structure and methods for representing the allocation, combination 
  and conversion of units of currency. 
  """
  use Application
  alias Argent.Currency 

  defstruct [:fractional, :currency]
  defdelegate format(argent, opts), to: Argent.Formatting
  defdelegate format(argent), to: Argent.Formatting

  @h __MODULE__

  @type fractional :: integer
  @type quantity :: number
  @type currency :: Currency.t
  @type options :: Keyword.t
  @type exchange :: module
  @type rate :: float
  @type code :: String.t
  @opaque t :: %@h{fractional: fractional, currency: currency}

  # Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Argent.Currency, [[name: Argent.Currency]]),
      worker(Argent.Exchange, [[name: Argent.Exchange]])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  # Struct and Instance

  @doc """
  Creates a new cash quantity of the provided currency. 

  ## Examples
  
      iex> Argent.new(100, "USD")
      #Argent<fractional:10000 currency:USD>

  """
  @spec new(quantity, code) :: t
  def new(quantity, code) do
    curr = Argent.Currency.find(code)
    fract = quantity * curr.subunit_to_unit
    %@h{fractional: fract, currency: curr}
  end

  @doc """
  Converts a cash quantity to a different currency using the exchange rate
  defined by the provided exchange. 

  ## Examples
    iex> Argent.Exchange.set_rate("USD", "EUR", 1.5)
    ...> Argent.new(100, "USD") |> Argent.convert_to("EUR")
    #Argent<fractional:15000 currency:EUR>

  """
  @spec convert_to(t, code, exchange) :: t
  def convert_to(argent, code, exchange \\ Argent.Exchange) do
    tcur = Argent.Currency.find(code)
    rate = exchange.get_rate(argent.currency.iso_code, tcur.iso_code)
    %@h{fractional: argent.fractional * rate, currency: tcur}
  end

  defimpl Inspect, for: Argent do
    import Inspect.Algebra

    def inspect(argent, _opts) do
      group(
        surround(
          "#Argent<",
          concat([
            concat("fractional:", to_string(trunc(argent.fractional))),
            break, concat("currency:", argent.currency.iso_code),
          ]),
          ">"
        )
      )
    end
  end
end
