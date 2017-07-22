defmodule GenServerAsync do
  @moduledoc """
  Gen server with no blocking calls

  # Ussage

  ```
  defmodule Queue do
    use Eyr.GenServerAsync

    def register(pid, user) do
      Eyr.GenServerAsync.call_async(pid, {:register, user})
    end

    # blocking call
    def handle_call({:register, user}, from, state) do
      with :not_found <- found_user(state, user) do
        # call async callback
        {:noreply, state}
      else
        {:found, user} ->
          # send reply to call
          {:reply, {:alredy_registered, user}, state}
      end
    end

    def handle_call({:async, {:register, user}}, from, state) do
      result = heavy_fun(user)
      {:reply, result, state}
    end
  end
  ```
  """

  defmacro __using__(opts \\ []) do
    quote do
      use GenServer
      import GenServerAsync.Base

      def handle_call({:call_async, message, opts}, from, state) do
        genserver_pid = self()
        pre_call = handle_call_async(:before, message, from, state)
        case(pre_call) do
          {:reply, result, state} ->
            {:reply, result, state}
          {:noreply, updated_state} ->
            current_pid = self()
            Task.start_link(fn ->
              {:reply, result} = handle_call_async(:call, message, self(), updated_state)
    
              GenServer.reply(from, result)
              GenServer.cast(genserver_pid, {:async_cast, message, result})
            end)
            {:noreply, updated_state}
        end
      end

      def handle_cast({:async_cast, message, result}, state) do
        handle_call_async(:finish, message, result, state)
      end
    end
  end

  def call_async(pid, message, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 10_000)
    GenServer.call(pid, {:call_async, message, opts}, timeout)
  end

end
