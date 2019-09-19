defmodule WorkingTimeManagerWeb.UserController do
  use WorkingTimeManagerWeb, :controller

  import Ecto.Query

  alias WorkingTimeManager.Repo

  alias WorkingTimeManager.Resource
  alias WorkingTimeManager.Resource.User

  action_fallback WorkingTimeManagerWeb.FallbackController

  def index(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    params = conn.query_params
    users = if Map.has_key?(params, "username") and Map.has_key?(params, "email") do
      query = from(u in User, where: u.username == ^params["username"] and u.email == ^params["email"])
      Repo.all(query)
    end
    if users != nil do
      render(conn, "index.json", users: users)
    else
      send_resp(conn, :ok, "No content")
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Resource.create_user(user_params) do
      email = user_params["email"]
      if Regex.match?(~r/[A-Za-z0-9-_]+@[A-Za-z0-9]+.[A-Za-z0-9]+$/, email) == true do
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.user_path(conn, :show, user))
        |> render("show.json", user: user)
      else
        raise "Your email #{email} is incorrect. Email must have this pattern : X@X.X"
      end
    else
      {:error, _message} -> send_resp(conn, :bad_request, "Bad request, cannot create user")
    end
  end

  def show(conn, %{"id" => id}) do
    case Resource.get_user(id) do
      nil -> send_resp(conn, :not_found, "User not found")
      user -> render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Resource.get_user!(id)

    with {:ok, %User{} = user} <- Resource.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    else
      {:error, _message} -> send_resp(conn, :bad_request, "Bad request, cannot update user")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Resource.get_user!(id)

    with {:ok, %User{}} <- Resource.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end