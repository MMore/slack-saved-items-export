defmodule SlackStarredExport.ChannelStore do
  alias SlackStarredExport.StarredMessage

  use GenServer

  # Client

  def start_link(_args) do
    IO.puts("Starting channel store...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_channel_name(channel_id) do
    GenServer.call(__MODULE__, {:get_channel_name, channel_id})
  end

  # Server

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call({:get_channel_name, channel_id}, _from, state) do
    case List.keyfind(state, channel_id, 0) do
      nil ->
        channel_name = StarredMessage.get_channel_name(channel_id)
        new_state = [{channel_id, channel_name} | state]
        {:reply, channel_name, new_state}

      {_channel_id, channel_name} ->
        {:reply, channel_name, state}
    end
  end
end
