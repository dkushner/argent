defmodule Argent.Exchange.UnknownCurrency do
  defexception [:message]

  @h __MODULE__

  def exception(value) do
    msg = "Could not find currency with code: #{value}."
    %@h{message: msg}
  end
end

