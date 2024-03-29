defmodule WorkingTimeManagerWeb.UserController do
  use WorkingTimeManagerWeb, :controller

  import Logger
  import Ecto.Query

  alias WorkingTimeManager.Repo
  alias WorkingTimeManagerWeb.Authent.Token
  alias WorkingTimeManagerWeb.Controllers.ControllerHelper
  alias WorkingTimeManager.Resource
  alias WorkingTimeManager.Resource.User

  action_fallback WorkingTimeManagerWeb.FallbackController

  def index(conn, _params) do
    conn = Plug.Conn.fetch_query_params(conn)
    params = conn.query_params
    users = if Map.has_key?(params, "email") do
      query = from(u in User, where: u.email == ^params["email"])
      Repo.all(query)
    end
    if users != nil do
      render(conn, "index.json", users: users)
    else
      send_resp(conn, :ok, "No content")
    end
  end

  def create(conn, %{"user" => user_params}) do
    email = user_params["email"]
    hashed_password = Bcrypt.hash_pwd_salt(user_params["password"])
    user_hashed_params = Map.put(user_params, "password", hashed_password)
    if Regex.match?(~r/[A-Za-z0-9-_]+@[A-Za-z0-9]+.[A-Za-z0-9]+$/, email) == false do
      raise "Your email #{email} is incorrect. Email must have this pattern : X@X.X"
    end
    user_with_same_email = Repo.one(from(u in User, where: u.email == ^email))
    if user_with_same_email != nil do
      conn
      |> put_status(:bad_request)
      |> json(%{error_message: "your email is already used"})
    else
      with {:ok, %User{} = user} <- Resource.create_user(user_hashed_params) do
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.user_path(conn, :show, user))
        |> render("show.json", user: user)
      else
        {:error, _message} -> send_resp(conn, :bad_request, "Bad request, cannot create user")
      end
    end
  end

  def show(conn, %{"id" => req_id}) do
    id = if req_id == "0" do
      conn.assigns.current_user.id
    else
      req_id
    end
    case Resource.get_user(id) do
      nil -> send_resp(conn, :not_found, "User not found")
      user -> render(conn, "show.json", user: user)
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
      query = from(u in User, where: u.email == ^email)
      user = Repo.one(query)
      if user != nil and Bcrypt.verify_pass(password, user.password) do
        extra_claims = %{"user_id" => Integer.to_string(user.id)}
        token = Token.generate_and_sign!(extra_claims)
        conn
        |> put_resp_cookie("session_jwt", token)
        |> json(%{ status: true })
      else
        json conn, %{ status: false }
      end
  end

  def sign_out(conn, _params) do
    conn
    |> delete_resp_cookie("session_jwt")
    |> json(%{message: "ok"})
  end

  def update(conn, %{"id" => id, "user" => user_supplied_params}) do
    with {:ok, _} <- ControllerHelper.hasRightsToEditUser(conn, id) do
      hashed_password = Bcrypt.hash_pwd_salt(user_supplied_params["password"])
      user_params = Map.put(user_supplied_params, "password", hashed_password)
      user = Resource.get_user!(id)
      with {:ok, %User{} = user} <- Resource.update_user(user, user_params) do
        render(conn, "show.json", user: user)
      else
        {:error, _message} -> send_resp(conn, :bad_request, "Bad request, cannot update user")
      end
    else
      {:error, message} -> conn |> send_resp(:unauthorized, message)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, _} <- ControllerHelper.hasRightsToEditUser(conn, id) do
      user = Resource.get_user!(id)
      with {:ok, %User{}} <- Resource.delete_user(user) do
        send_resp(conn, :ok, "deleted")
      end
    else
      {:error, message} -> conn |> send_resp(:unauthorized, message)
    end
  end
end
