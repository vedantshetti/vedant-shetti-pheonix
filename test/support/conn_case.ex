defmodule TodoerPhoenixWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint TodoerPhoenixWeb.Endpoint

      use TodoerPhoenixWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import TodoerPhoenixWeb.ConnCase
    end
  end

  setup tags do
    TodoerPhoenix.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
