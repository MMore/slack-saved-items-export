defmodule SSIExport.UserStore do
  alias SSIExport.DataAdapter

  use GenServer

  # Client

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_user_info(user_id) do
    GenServer.call(__MODULE__, {:get_user_info, user_id}, :infinity)
  end

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_user_info, user_id}, _from, state, data_mod \\ DataAdapter) do
    case List.keyfind(state, user_id, 0) do
      nil ->
        user = data_mod.get_user_info(user_id)

        new_state = [{user_id, user} | state]
        {:reply, user, new_state}

      {_user_id, user} ->
        {:reply, user, state}
    end
  end
end
