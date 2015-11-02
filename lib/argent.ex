defmodule Argent do
  use Application
  alias Argent.Currency 

  defstruct [:fractional, :currency]

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
  """
  @spec new(quantity, code) :: t
  def new(quantity, code) do
    curr = Argent.Currency.find(code)
    fract = quantity * curr.subunit_to_unit
    %@h{fractional: fract, currency: curr}
  end

  @spec convert_to(t, code, exchange) :: t
  def convert_to(argent, code, exchange \\ Argent.Exchange) do
    tcur = Argent.Currency.find(code)
    rate = Argent.Exchange.get_rate(argent.currency.iso_code, tcur.iso_code)
    %@h{fractional: argent.fractional * rate, currency: tcur}
  end

  
  @spec format(t, options) :: String.t
  def format(%@h{fractional: f, currency: c}, opts \\ []) do
    
  end

  defimpl Inspect, for: Argent do
    import Inspect.Algebra

    def inspect(argent, opts) do
      group(
        surround(
          "#Argent<",
          concat([
            break, concat("fractional:", to_string(argent.fractional)),
            break, concat("currency:", argent.currency.iso_code),
          ]),
          ">"
        )
      )
    end

  end
end
