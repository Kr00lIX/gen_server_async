defmodule Example do
  use GenServerAsync

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def add(number) do
    GenServerAsync.call_async(__MODULE__, {:add, number})
  end

  def handle_call_async(:before, {:add, number}, _from, state) when number > 10 do
    # IO.inspect(state, label: "add before")
    {:noreply, Map.put(state, number, :lock)}
  end
  def handle_call_async(:before, {:add, number}, _from, state) do
    # IO.inspect(state, label: "add with lock")
    {:reply, number, Map.put(state, number, :without_lock)}
  end

  def handle_call_async(:call, {:add, number}, _task_pid) do
    # IO.inspect([state: state], label: "add call")
    Process.sleep(5_000)
    {:reply, number}
  end

  def handle_call_async(:finish, {:add, number}, result, state) do
    # IO.inspect([state: state, result: result], label: "add finish")
    {:noreply, Map.put(state, number, :finish)}
  end
end
