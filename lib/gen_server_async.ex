defmodule GenServerAsync do
  @moduledoc ~S"""
  Gen Server with no blocking calls

  ## Example

  ```elixir
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

  ## Client / Server APIs
  Although in the example above we have used GenServer.start_link/3 and friends
  to directly start and communicate with the server, most of the time we don't
  call the GenServer functions directly. Instead, we wrap the calls in new
  functions representing the public API of the server.

  Here is a better implementation of our Stack module:

  ```elixir
    defmodule Stack do
      use GenServer

      # Client

      def start_link(default) do
        GenServer.start_link(__MODULE__, default)
      end

      def push(pid, item) do
        GenServer.cast(pid, {:push, item})
      end

      def pop(pid) do
        GenServer.call(pid, :pop)
      end

      # Server (callbacks)

      def handle_call(:pop, _from, [h | t]) do
        {:reply, h, t}
      end

      def handle_call(request, from, state) do
        # Call the default implementation from GenServer
        super(request, from, state)
      end

      def handle_cast({:push, item}, state) do
        {:noreply, [item | state]}
      end

      def handle_cast(request, state) do
        super(request, state)
      end
    end

    ## Debugging
    
  ```

  In practice, it is common to have both server and client functions in the same
  module. If the server and/or client implementations are growing complex, you
  may want to have them in different modules.
  """

  @type result :: term()
  @type message :: term()
  @type state :: term()

  @doc """
  TODO:

  """
  @callback handle_call_async(message, state) :: {:reply, result}

  @doc """
  TODO:

  If this callback is not implemented, the default implementation by
  `use GenServerAsync` will return `{:noreply, state}`.
  """
  @callback handle_cast_async(message :: term(), result, state) :: {:noreply, state}

  @optional_callbacks handle_cast_async: 3

  @doc """
  Starts a `GenServerAsync` process linked to the current process.

  See `GenServer.start_link/3`.
  """
  @spec start_link(GenServer.module(), any(), GenServer.options()) :: GenServer.on_start()
  defdelegate start_link(module, args, options \\ []), to: GenServer

  @doc """
  Makes a synchronous call to the `server` and waits for its reply.

  See `GenServer.call/3`.
  """
  @spec call(GenServer.server(), term(), timeout()) :: term()
  defdelegate call(server, message, timeout \\ 5000), to: GenServer
  
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
                  GenServer.cast(genserver_pid, {:async_cast, from, message, {:error, error}})
              end
            end)

            {:noreply, updated_state}
        end
      end

      @doc false
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

      @doc false
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
  Makes a synchronous call to the server and waits for its reply.

  The client sends the given request to the `server` and waits until a reply
  arrives or a timeout occurs. `c:handle_call/3` will be called on the server to
  handle the request. 

  `c:handle_cast_async/3` will be called an asynchronous if `c:handle_call/3` returns `{:no_reply, state}`.

  """
  @spec call_async(GenServer.server(), message) :: result()
  def call_async(pid, message, opts \\ []) do
    timeout = opts[:timeout] || 20_000
    event_name = (Keyword.get(opts, :async, true) && :call_async) || :call_no_async
    call(pid, {event_name, pid, message, opts}, timeout)
  end
end
