# GenServerAsync 
-----
[![Build Status](https://travis-ci.org/Kr00lIX/gen_server_async.svg?branch=master)](https://travis-ci.org/Kr00lIX/gen_server_async)
[![Hex pm](https://img.shields.io/hexpm/v/gen_server_async.svg?style=flat)](https://hex.pm/packages/gen_server_async)
[![Coverage Status](https://coveralls.io/repos/github/Kr00lIX/gen_server_async/badge.svg?branch=master)](https://coveralls.io/github/Kr00lIX/gen_server_async?branch=master)


GenServerAsync adds a `call_async` method that allows you to run `GenServer.call/3` method in a separate non-blocking GenServer process.


Extends the GenServer behavior, adds a `.call_async(server_pid, message)` method to it, which allows you to divide the blocking `handle_call` into three callbacks.
`handle_call(message, from, state)` –

`handle_call_async(message, call_state)` – asynchronously call this

`handle_cast_async(message, call_async_result, state)` - 

```elixir
# Start the server
{:ok, pid} = GenServerAsync.start_link(ExampleServer, state)
GenServerAsync.call_async(pid, message)

defmodule ExampleServer do
  use GenServerAsync

  # Makes a synchronous call to the server and waits for its reply.
  def handle_call(message, from, state) do
    if could_reply_immediately?(message) do
      {:reply, response, updated_state}
    else 

      # update state and calls `handle_call_async` asynchronously
      {:no_reply, updated_state}
    end
  end

  @doc """

  """
  def handle_call_async(message, call_state) do
    call_async_result = ... # complex  calculation
    {:reply, call_async_result}
  end

  # sync GenServer state after handle_call_async if needed
  def handle_cast_async(_message, call_async_result, state) do
    {:noreply, state}
  end 
  
end
```


## Installation
It's available in Hex, the package can be installed as:
Add `gen_server_async` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:gen_server_async, ">= 0.0.1"}]
end
```

Documentation can be found at [https://hexdocs.pm/gen_server_async](https://hexdocs.pm/gen_server_async/).


## License
This software is licensed under [the MIT license](LICENSE.md).