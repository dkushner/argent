defmodule Argent.Currency do
  alias Argent.CurrencyStore
  use GenServer
  
  @h __MODULE__

  @data_path "priv/currencies.ex"

  @type code :: String.t
  @type iso_numeric :: integer
  @opaque t :: %@h{
    name: String.t,                 
    iso_code: String.t,             
    iso_numeric: String.t,          
    alternate_symbols: [String.t],  
    disambiguate_symbol: String.t,  
    html_entity: String.t,
    decimal_mark: String.t,
    thousands_separator: String.t,
    priority: integer,
    symbol: String.t,
    smallest_denomination: integer,
    subunit: String.t,
    subunit_to_unit: integer,
    symbol_first: boolean
  }

  defstruct \
    name: "",
    iso_code: "",
    iso_numeric: "",
    alternate_symbols: [],
    disambiguate_symbol: "",
    html_entity: "$",
    decimal_mark: ".",
    thousands_separator: ",",
    priority: 100,
    symbol: "$",
    smallest_denomination: 1,
    subunit: "Cent",
    subunit_to_unit: 100,
    symbol_first: true

  # Instance Methods
  @spec exponent(t) :: float
  def exponent(%@h{subunit_to_unit: s}) do
    :math.log10(s)
  end

  @spec symbol_position(t) :: atom
  def symbol_position(%@h{symbol_first: s}) do
    s && :before || :after
  end

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    table = :ets.new(__MODULE__, [:set, :public, :named_table, 
      {:read_concurrency, true}])

    {currencies, _} = Code.eval_file(Application.app_dir(:argent, @data_path))

    Enum.each(currencies, fn(c) ->
      :ets.insert(table, {c.iso_code, Map.merge(%@h{}, c)})
    end)

    {:ok, %{table: table}}
  end

  @spec find(code) :: {:ok, t} | :error
  def find(code) do
    GenServer.call(__MODULE__, {:find, code})
  end

  @spec find_by_iso_numeric(iso_numeric) :: t | nil
  @spec find_by_iso_numeric(String.t) :: t | nil
  def find_by_iso_numeric(code) when is_binary(code) do
    GenServer.call(__MODULE__, {:find_by_iso_numeric, code})
  end

  def find_by_iso_numeric(code) when is_integer(code), 
    do: find_by_iso_numeric(Integer.to_string(code))

  @spec register(%{iso_code: code}) :: t
  def register(%{iso_code: iso_code}=data) do
    GenServer.call(__MODULE__, {:register, data})
  end

  # Server API
  def handle_call({:find, code}, _from, state) do
    case :ets.lookup(state.table, code) do
      [{^code, info}] -> {:reply, info, state}
      [] -> {:no_reply, state}
    end
  end

  def handle_call({:find_by_iso_numeric, code}, _from, state) do
    case :ets.match_object(state.table, {:"_", %{iso_numeric: code}}) do
      [{_, curr}] -> {:reply, curr, state}
      [] -> {:no_reply, state}
    end
  end

  def handle_call({:register, %{iso_code: code}=info}, _from, state) do
    curr = Map.merge(%@h{}, info)
    :ets.insert(state.table, {code, curr})
    {:reply, curr, state}
  end
end

