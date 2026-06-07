defmodule EvoPhxKit.Test.MockSessionProvider do
  @behaviour EvoPhxKit.SessionProvider

  @impl true
  def session_revoked?(user_id) do
    user_id in Process.get(:revoked_sessions, [])
  end

  @impl true
  def clear_revoked_session(user_id) do
    revoked = Process.get(:revoked_sessions, [])
    Process.put(:revoked_sessions, List.delete(revoked, user_id))
    :ok
  end

  def revoke(user_id) do
    revoked = Process.get(:revoked_sessions, [])
    Process.put(:revoked_sessions, [user_id | revoked])
  end

  def reset do
    Process.put(:revoked_sessions, [])
  end
end
