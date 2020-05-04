defmodule GenServerAsync.CalendarTest do
  use ExUnit.Case, async: true

  alias GenServerAsync.Support.CalendarService

  setup do
    {:ok, pid} = GenServerAsync.start_link(CalendarService, :ok)

    [pid: pid]
  end

  test "call async add", %{pid: pid} do
    task1 =
      Task.async(fn ->
        {:ok, 100} == GenServerAsync.call_async(pid, {:add, 100})
      end)

    task2 =
      Task.async(fn ->
        {:ok, 50} == GenServerAsync.call_async(pid, {:add, 50})
      end)

    task3 =
      Task.async(fn ->
        {:ok, 5} == GenServerAsync.call_async(pid, {:add, 5})
      end)

    task4 =
      Task.async(fn ->
        {:ok, 6} == GenServerAsync.call_async(pid, {:add, 6})
      end)

    [task1, task2, task3, task4] |> Enum.each(&Task.await/1)
  end
end
