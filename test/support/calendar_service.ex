defmodule GenServerAsync.Support.CalendarService do
  @moduledoc """
  Simple GenServerAsync usage

  use only async calling
  """
  use GenServerAsync

  def handle_call({:add, _calendar}, _from, :ok) do
    {:noreply, :ok}
  end

  def handle_call_async({:add, timeout}, :ok) do
    # IO.inspect timeout, label: "call async "
    # emulate hard work
    Process.sleep(timeout)
    # IO.inspect timeout, label: "call async result"
    {:reply, {:ok, timeout}}
  end
end
