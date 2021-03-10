defmodule SlackStarredExport.UserStore do
  alias SlackStarredExport.Data

  use GenServer

  # Client

  def start_link(_args) do
    IO.puts("Starting user store...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_user_info(user_id) do
    GenServer.call(__MODULE__, {:get_user_info, user_id})
  end

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_user_info, user_id}, _from, state, data_mod \\ Data) do
    case List.keyfind(state, user_id, 0) do
      nil ->
        user_info = data_mod.get_user_info(user_id)

        user = %Data.User{
          user_id: user_id,
          real_name: user_info["real_name"],
          title: user_info["profile"]["title"],
          image_24: user_info["profile"]["image_24"]
        }

        new_state = [{user_id, user} | state]
        {:reply, user, new_state}

      {_user_id, user} ->
        {:reply, user, state}
    end
  end
end
