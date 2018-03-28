defmodule GenServerAsync do
  @moduledoc """
  Gen server with no blocking calls

  # Ussage

  ```
  defmodule Queue do
    use GenServerAsync

    def register(pid, user) do
      GenServerAsync.call_async(pid, {:register, user})
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

    # called async
    def handle_call_async({:register, user}, from, state) do
      result = heavy_function(user)
      {:reply, result, state}
    end

    # called on finish `handle_call_async` with result
    def handle_cast_async({:register, user}, result, state) do
      # update state if needed
      {:noreply, state}
    end
  end
  ```
  """
  @type result :: term()
  @type message :: term()
  @type state :: term()

  @callback handle_call_async(message, state) :: {:reply, result}

  @callback handle_cast_async(message, result, state) :: {:noreply, state}

  defdelegate start_link(module, args, options \\ []), to: GenServer

  defdelegate call(server, message, timeout \\ 5000), to: GenServer
  

  defmacro __using__(_opts \\ []) do
    quote do
      use GenServer
      require Logger

      def init(state) do
        {:ok, state}
      end

      def handle_call({:call_async, genserver_pid, message, opts}, from, state) do
        case handle_call(message, from, state) do
          {:reply, result, state} ->
            {:reply, result, state}

          {:noreply, updated_state} ->
            Task.start_link(fn ->
              try do
                {:reply, result} = handle_call_async(message, updated_state)
                GenServer.cast(genserver_pid, {:async_cast, from, message, result})
              rescue
                error ->
                  Logger.error("Handle call async error: #{inspect(error)}")
                  GenServer.cast(genserver_pid, {:async_cast, from, message, {:error, error}})
              end
            end)

            {:noreply, updated_state}
        end
      end

      def handle_call({:call_no_async, genserver_pid, message, opts}, from, state) do
        case handle_call(message, from, state) do
          {:reply, response, state} ->
            {:reply, response, state}

          {:noreply, call_state} ->
            {:reply, result} = handle_call_async(message, call_state)
            {:noreply, updated_state} = handle_cast_async(message, result, call_state)
            {:reply, result, updated_state}
        end
      end

      def handle_cast({:async_cast, from, message, result}, state) do
        GenServer.reply(from, result)
        handle_cast_async(message, result, state)
      end

      def handle_cast_async(_message, _result, state) do
        {:noreply, state}
      end 

      defoverridable init: 1, handle_cast_async: 3
    end
  end

  @doc ~S"""

  """
  def call_async(pid, message, opts \\ []) do
    timeout = opts[:timeout] || 20_000
    event_name = (Keyword.get(opts, :async, true) && :call_async) || :call_no_async
    GenServer.call(pid, {event_name, pid, message, opts}, timeout)
  end
end
