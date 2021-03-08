defmodule SlackStarredExport.UserStore do
  alias SlackStarredExport.Data

  use GenServer

  # Client

  def start_link(_args) do
    IO.puts("Starting user store...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_user_name(user_id) do
    GenServer.call(__MODULE__, {:get_user_name, user_id})
  end

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_user_name, user_id}, _from, state) do
    case List.keyfind(state, user_id, 0) do
      nil ->
        user_name = Data.get_user_name(user_id)
        new_state = [{user_id, user_name} | state]
        {:reply, user_name, new_state}

      {_user_id, user_name} ->
        {:reply, user_name, state}
    end
  end
end
