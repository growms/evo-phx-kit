defmodule EvoPhxKit.SessionProvider do
  @moduledoc """
  Optional behaviour for session revocation checks.

  If not configured, session revocation is disabled in RequireAuth.

  ## Public API

  - `session_revoked?/1` — check if a user's session has been revoked
  - `clear_revoked_session/1` — clear the revocation flag for a user
  """

  @callback session_revoked?(user_id :: term()) :: boolean()
  @callback clear_revoked_session(user_id :: term()) :: :ok
end
