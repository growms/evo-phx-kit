defmodule EvoPhxKit.Plugs.SetLocale do
  @moduledoc false
  import Plug.Conn

  @cookie_max_age 365 * 24 * 3600

  def init(opts), do: opts

  def call(conn, _opts) do
    locales = EvoPhxKit.locales()
    default = EvoPhxKit.default_locale()
    cookie_name = EvoPhxKit.locale_cookie_name()
    session_key = cookie_name

    locale =
      locale_from_user(conn, locales) ||
        locale_from_session(conn, session_key, locales) ||
        locale_from_cookie(conn, cookie_name, locales) ||
        locale_from_accept_language(conn, locales) ||
        default

    Gettext.put_locale(EvoPhxKit.gettext_module(), locale)

    conn
    |> put_session(session_key, locale)
    |> put_resp_cookie(cookie_name, locale, max_age: @cookie_max_age, same_site: "Lax")
    |> assign(:locale, locale)
  end

  defp locale_from_user(conn, locales) do
    user_provider = EvoPhxKit.user_provider()
    user_key = EvoPhxKit.session_user_key()

    case conn.assigns[:current_user] do
      nil ->
        case get_session(conn, user_key) do
          nil -> nil
          user_id -> locale_from_provider(user_provider, user_id, locales)
        end

      user ->
        case user_provider.get_user_locale(user) do
          locale when is_binary(locale) -> if locale in locales, do: locale
          _ -> nil
        end
    end
  end

  defp locale_from_provider(user_provider, user_id, locales) do
    user = try do
      user_provider.get_user!(user_id)
    rescue
      _ -> nil
    end

    case user do
      nil -> nil
      u ->
        case user_provider.get_user_locale(u) do
          locale when is_binary(locale) -> if locale in locales, do: locale
          _ -> nil
        end
    end
  end

  defp locale_from_session(conn, session_key, locales) do
    case get_session(conn, session_key) do
      locale when is_binary(locale) -> if locale in locales, do: locale
      _ -> nil
    end
  end

  defp locale_from_cookie(conn, cookie_name, locales) do
    case conn.cookies[cookie_name] do
      locale when is_binary(locale) -> if locale in locales, do: locale
      _ -> nil
    end
  end

  defp locale_from_accept_language(conn, locales) do
    case get_req_header(conn, "accept-language") do
      [header | _] -> parse_accept_language(header, locales)
      _ -> nil
    end
  end

  defp parse_accept_language(header, locales) do
    header
    |> String.split(",")
    |> Enum.map(fn part ->
      part
      |> String.trim()
      |> String.split(";")
      |> List.first()
      |> String.downcase()
      |> String.split("-")
      |> List.first()
    end)
    |> Enum.find(&(&1 in locales))
  end
end
