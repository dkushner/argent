defmodule Argent.Exchange do
  @behaviour Argent.Exchange.Provider

  # Client API

  def start_link(opts \\ []) do 
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    table = :ets.new(__MODULE__, [:set, :public, :named_table,
      {:read_concurrency, true}])

    {:ok, %{table: table}}
  end

  @doc """
  Sets the available rate from one currency to another. The inverse rate will also
  be added to the rate store. 

  ## Examples
  
      iex> Argent.Exchange.set_rate("USD", "EUR", 1.5)
      :ok

      iex> Argent.Exchange.get_rate("USD")

  """
  def set_rate(from, to, rate) do
    GenServer.cast(__MODULE__, {:set_rate, from, to, rate})
  end

  def get_rate(from, to) do
    GenServer.call(__MODULE__, {:get_rate, from, to})
  end

  # Server API

  def handle_cast({:set_rate, from, to, rate}, state) do
    :ets.insert(state.table, {{from, to}, rate})
    :ets.insert(state.table, {{to, from}, rate})
    {:noreply, state}
  end

  def handle_call({:get_rate, from, to}, _from, state) do
    case :ets.lookup(state.table, {from, to}) do
      [{{^from, ^to}, rate}] -> {:reply, rate, state}
      [] -> {:reply, nil, state}
    end
  end

end
