defmodule DataTest do
  alias SSIExport.Data
  alias Support.TestHelper
  use ExUnit.Case

  describe "get channel info" do
    test "for public channel" do
      channel_data_fn = fn id ->
        send(self(), {:asked_for_channel, id})
        {:ok, %{body: TestHelper.parsed_json_for_endpoint("conversations.info_channel")}}
      end

      assert Data.get_channel_info("channel_id", channel_data_fn) == {:public, "general"}

      assert_received {:asked_for_channel, "channel_id"}
    end

    test "for private group channel" do
      channel_data_fn = fn id ->
        send(self(), {:asked_for_channel, id})
        {:ok, %{body: TestHelper.parsed_json_for_endpoint("conversations.info_private_group")}}
      end

      assert Data.get_channel_info("channel_id", channel_data_fn) == {:private_group, "admins"}

      assert_received {:asked_for_channel, "channel_id"}
    end

    test "for im channel" do
      channel_data_fn = fn id ->
        send(self(), {:asked_for_channel, id})
        {:ok, %{body: TestHelper.parsed_json_for_endpoint("conversations.info_im")}}
      end

      assert Data.get_channel_info("channel_id", channel_data_fn, TestUserStore) ==
               {:im, "real_name_U0M9LEYBB"}

      assert_received {:asked_for_channel, "channel_id"}
    end

    test "for unknown channel type" do
      channel_data_fn = fn id ->
        send(self(), {:asked_for_channel, id})
        {:ok, %{body: TestHelper.parsed_json_for_endpoint("conversations.info_unknown")}}
      end

      assert_raise RuntimeError,
                   ~r/error: channel_info_type unknown (.*)/,
                   fn -> Data.get_channel_info("channel_id", channel_data_fn) end

      assert_received {:asked_for_channel, "channel_id"}
    end
  end
end
