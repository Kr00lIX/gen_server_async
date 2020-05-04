defmodule GenServerAsync.RegisterUserTest do
  use ExUnit.Case, async: true

  alias GenServerAsync.Support.RegisterUser
  alias GenServerAsync.Support.RegisterUser.User

  setup do
    {:ok, pid} = GenServerAsync.start_link(RegisterUser, %{})

    valid_user = %User{name: "valid_user", age: nil, state: :init}
    invalid_user = %User{name: "invalid_user", age: nil, state: :invalid}
    [pid: pid, valid_user: valid_user, invalid_user: invalid_user]
  end

  test "expect add use to state", %{pid: pid, valid_user: user} do
    task =
      Task.async(fn ->
        assert {:ok, %User{name: "valid_user", state: :registered}} =
                 GenServerAsync.call_async(pid, {:register, user})

        assert %User{name: "valid_user", state: :registered} =
                 GenServerAsync.call(pid, {:get, user.name})
      end)

    Process.sleep(10)
    assert %User{name: "valid_user", state: :init} = GenServerAsync.call(pid, {:get, user.name})
    Task.await(task)
  end

  test "expect no add invalid user to state", %{pid: pid, invalid_user: user} do
    task =
      Task.async(fn ->
        assert {:error, :invalid} = GenServerAsync.call_async(pid, {:register, user})
        assert :not_found = GenServerAsync.call(pid, {:get, user.name})
      end)

    Process.sleep(10)

    assert assert %User{name: "invalid_user", state: :invalid} =
                    GenServerAsync.call(pid, {:get, user.name})

    Task.await(task)
    assert :not_found == GenServerAsync.call(pid, {:get, user.name})
  end

  test "expect error on calling twice", %{pid: pid, valid_user: user} do
    task1 =
      Task.async(fn ->
        assert {:ok, %User{name: "valid_user", state: :registered}} =
                 GenServerAsync.call_async(pid, {:register, user})

        assert %User{name: "valid_user", state: :registered} =
                 GenServerAsync.call(pid, {:get, user.name})
      end)

    Process.sleep(10)

    task2 =
      Task.async(fn ->
        assert {:error, :exists} == GenServerAsync.call_async(pid, {:register, user})

        assert %User{name: "valid_user", state: :init} =
                 GenServerAsync.call(pid, {:get, user.name})
      end)

    task3 =
      Task.async(fn ->
        assert {:error, :exists} == GenServerAsync.call_async(pid, {:register, user})

        assert %User{name: "valid_user", state: :init} =
                 GenServerAsync.call(pid, {:get, user.name})
      end)

    [task1, task2, task3] |> Enum.each(&Task.await/1)

    assert %User{name: "valid_user", state: :registered} =
             GenServerAsync.call(pid, {:get, user.name})
  end
end
