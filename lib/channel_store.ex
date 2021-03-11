defmodule SSIExport.ChannelStore do
  alias SSIExport.Data

  use GenServer

  # Client

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_channel_name(channel_id) do
    GenServer.call(__MODULE__, {:get_channel_name, channel_id}, :infinity)
  end

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_channel_name, channel_id}, _from, state, data_mod \\ Data) do
    case List.keyfind(state, channel_id, 0) do
      nil ->
        channel_name = data_mod.get_channel_name(channel_id)
        new_state = [{channel_id, channel_name} | state]
        {:reply, channel_name, new_state}

      {_channel_id, channel_name} ->
        {:reply, channel_name, state}
    end
  end
end
