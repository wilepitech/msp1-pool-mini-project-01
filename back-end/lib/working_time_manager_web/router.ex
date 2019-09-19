defmodule WorkingTimeManagerWeb.Router do
  use WorkingTimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WorkingTimeManagerWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]

    scope "/workingtimes/" do
      get "/:userid",     WorkingTimeController, :index
      post "/:userid",    WorkingTimeController, :create
      get "/:userid/:id", WorkingTimeController, :show
      delete "/:id",      WorkingTimeController, :delete
    end

    scope "/clocks" do
      get "/:user",  ClockController, :getclock
      post "/:user", ClockController, :clock
    end
  end

end
