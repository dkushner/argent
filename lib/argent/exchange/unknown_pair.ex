defmodule Argent.Exchange.UnknownPair do
  defexception [:message]

  @h __MODULE__

  def exception({from, to}) do
    msg = "Could not find rate for specified pair: {#{from}, #{to}}."
    %@h{message: msg}
  end
end
