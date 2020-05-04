defmodule GenServerAsync do
  @moduledoc ~S"""
  Gen Server for preventing blocking GenServer process on `c:handle_call/3` callbacks.
  See more in `GenServer`.

  ## Example

  ```elixir
  defmodule Queue do
    use GenServerAsync

    @server_name __MODULE__

    def start_link(default) do
      GenServerAsync.start_link(__MODULE__, default, name: @server_name)
    end

    def register(user) do
      GenServerAsync.call_async(@server_name, {:register, user})
    end

    # blocking call
    def handle_call({:register, user}, from, state) do
      with :not_found <- found_user(state, user) do
        # call async callback
        {:noreply, state}
      else
        {:found, user} ->
          # send reply to from
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

  ## Debugging
  Use `async: false` for disable asynchonious calling `c:handle_call_async/2` for debuging. 

  ```elixir
  GenServerAsync.call_async(server, request, async: false)
  ```
  """

  @typedoc "Result of calculation in `handle_call_async` method."
  @type result :: term()

  @typedoc "Request message for mathcing callback"
  @type request :: term()

  @typedoc "GenServer state"
  @type state :: term()


  @doc """

  TODO:

  """
  @callback handle_call_async(request, state) :: {:reply, result}

  @doc """
  Invoked to handle asynchronous
  request is the request request sent by a cast/2 and state is the current state of the GenServer.

  If this callback is not implemented, the default implementation by
  `use GenServerAsync` will return `{:noreply, state}`.
  """
  @callback handle_cast_async(request :: term(), result, state) :: {:noreply, state}

  @optional_callbacks handle_cast_async: 3

  @doc """
  Starts a `GenServerAsync` process linked to the current process.

  See `GenServer.start_link/3`.
  """
  @spec start_link(module(), any(), GenServer.options()) :: GenServer.on_start()
  defdelegate start_link(module, args, options \\ []), to: GenServer

  @doc """
  Makes a synchronous call to the `server` and waits for its reply.

  See `GenServer.call/3`.
  """
  @spec call(GenServer.server(), term(), timeout()) :: term()
  defdelegate call(server, request, timeout \\ 5000), to: GenServer

  @doc """
  Sends an asynchronous request to the `server`.

  See `GenServer.cast/2`.
  """
  @spec cast(GenServer.server(), term()) :: :ok
  defdelegate cast(server, request), to: GenServer

  @doc """
  Replies to a client.

  See `GenServer.reply/2`.
  """
  @spec reply(GenServer.from(), term()) :: :ok
  defdelegate reply(client, reply), to: GenServer

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, Macro.escape(opts)
      @behaviour GenServerAsync

      def init(state) do
        {:ok, state}
      end

      @doc false
      def handle_call({:call_async, genserver_pid, request, opts}, from, state) do
        case handle_call(request, from, state) do
          {:reply, result, state} ->
            {:reply, result, state}

          {:noreply, updated_state} ->
            Task.start_link(fn ->
              try do
                {:reply, result} = handle_call_async(request, updated_state)
                GenServer.cast(genserver_pid, {:async_cast, from, request, result})
              rescue
                error ->
                  GenServer.cast(genserver_pid, {:async_cast, from, request, {:error, error}})
              end
            end)

            {:noreply, updated_state}
        end
      end

      @doc false
      def handle_call({:call_no_async, genserver_pid, request, opts}, from, state) do
        case handle_call(request, from, state) do
          {:reply, response, state} ->
            {:reply, response, state}

          {:noreply, call_state} ->
            {:reply, result} = handle_call_async(request, call_state)
            {:noreply, updated_state} = handle_cast_async(request, result, call_state)
            {:reply, result, updated_state}
        end
      end

      @doc false
      def handle_cast({:async_cast, from, request, result}, state) do
        GenServer.reply(from, result)
        handle_cast_async(request, result, state)
      end

      def handle_cast_async(_request, _result, state) do
        {:noreply, state}
      end

      defoverridable init: 1, handle_cast_async: 3
    end
  end

  @doc ~S"""
  Makes a synchronous call to the server and waits for its reply.

  The client sends the given request to the `server` and waits until a reply
  arrives or a timeout occurs. `c:handle_call/3` will be called on the server to
  handle the request. 

  `c:handle_cast_async/3` will be called an asynchronous if `c:handle_call/3` returns `{:no_reply, state}`.

  `c:handle_cast_async/3` called synchroniosly after `c:handle_cast_async/3` callback.

  """
  @spec call_async(GenServer.server(), request) :: result()
  def call_async(pid, request, opts \\ []) do
    timeout = opts[:timeout] || 20_000
    event_name = (Keyword.get(opts, :async, true) && :call_async) || :call_no_async
    call(pid, {event_name, pid, request, opts}, timeout)
  end
end
