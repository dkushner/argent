defmodule Argent.Exchange.Provider do
  use Behaviour 

  @type currency :: Argent.Currency.t
  @type rate :: float
  @type info :: %{iso_code: String.t}
  @type code :: String.t
  @type options :: Keyword.t

  @callback set_rate(code, code, rate) :: no_return
  @callback get_rate(code, code) :: rate
end
