defmodule GenServerAsync.Support.RegisterUser do
  use GenServerAsync

  defmodule User do
    defstruct [:name, :age, :state]
  end

  def init(init_state) do
    {:ok, init_state}
  end

  def handle_call({:register, user}, _from, state) do
    # IO.inspect(state, label: "call register")
    if Map.has_key?(state, user.name) do
      {:reply, {:error, :exists}, state}
    else
      updated_state = Map.put(state, user.name, user)
      {:noreply, updated_state}
    end
  end

  @doc """
  Get user by name (calls sync)
  """
  def handle_call({:get, name}, _from, state) do
    # IO.inspect(state, label: "call get name - #{name}")
    if Map.has_key?(state, name) do
      {:reply, state[name], state}
    else
      {:reply, :not_found, state}
    end
  end

  @doc """
  Register all users  {:ok, user} for all 
  """  
  def handle_call_async({:register, %User{state: :init}=user}, _state) do
    # IO.inspect(state, label: "call async valid")
    # emulate hard work
    Process.sleep(50)
    updated_user = %{user | state: :registered}
    {:reply, {:ok, updated_user}}
  end

  def handle_call_async({:register, _user}, _state) do
    # emulate hard work
    Process.sleep(20)
    {:reply, {:error, :invalid}}
  end

  @doc """
  add to state on {:ok, user}
  delete from state on {:error, user}
  """
  def handle_cast_async({:register, user}, {:error, :invalid}, state) do
    updated_state = Map.delete(state, user.name)
    {:noreply, updated_state}
  end
  def handle_cast_async({:register, _user}, {:ok, registered_user}, state) do
    updated_state = Map.put(state, registered_user.name, registered_user)
    {:noreply, updated_state}
  end

end