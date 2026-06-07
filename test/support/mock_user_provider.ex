defmodule EvoPhxKit.Test.MockUserProvider do
  @behaviour EvoPhxKit.UserProvider

  @impl true
  def get_user!(id) do
    case Process.get(:mock_users, %{})[id] do
      nil -> raise "User not found: #{inspect(id)}"
      user -> user
    end
  end

  @impl true
  def get_user_by_email(email) do
    Process.get(:mock_users, %{})
    |> Map.values()
    |> Enum.find(&(&1.email == email))
  end

  @impl true
  def get_user_locale(user), do: user[:locale] || user.locale

  def put_user(id, user) do
    users = Process.get(:mock_users, %{})
    Process.put(:mock_users, Map.put(users, id, user))
  end

  def reset do
    Process.put(:mock_users, %{})
  end
end
