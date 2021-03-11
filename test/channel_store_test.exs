defmodule ChannelStoreTest do
  alias SSIExport.ChannelStore
  use ExUnit.Case

  defmodule TestDataMod do
    def get_channel_name(channel_id) do
      send(self(), :asked_for_channel_name)
      "channel_name_#{channel_id}"
    end
  end

  test "asks external service for channel name if not in cache" do
    assert ChannelStore.handle_call({:get_channel_name, "channel_id"}, nil, [], TestDataMod) ==
             {:reply, "channel_name_channel_id", [{"channel_id", "channel_name_channel_id"}]}

    assert_received :asked_for_channel_name
  end

  test "asks NOT external service for channel name if in cache" do
    current_state = [{"channel_id", "channel_name_channel_id"}, {"123", "channel_123"}]

    assert ChannelStore.handle_call(
             {:get_channel_name, "channel_id"},
             nil,
             current_state,
             TestDataMod
           ) ==
             {:reply, "channel_name_channel_id", current_state}

    refute_received :asked_for_channel_name
  end
end
