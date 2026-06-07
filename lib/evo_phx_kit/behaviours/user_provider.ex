defmodule EvoPhxKit.UserProvider do
  @moduledoc """
  Behaviour for user lookup and locale retrieval.

  ## Public API

  - `get_user!/1` — fetch a user by ID, raise if not found
  - `get_user_by_email/1` — fetch a user by email, return nil if not found
  - `get_user_locale/1` — return the locale string from a user struct
  """

  @callback get_user!(id :: term()) :: struct()
  @callback get_user_by_email(email :: String.t()) :: struct() | nil
  @callback get_user_locale(user :: struct()) :: String.t() | nil
end
