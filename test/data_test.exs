defmodule DataTest do
  alias SSIExport.Data
  alias Support.TestHelper
  use ExUnit.Case

  defmodule TestUserStore do
    def get_user_info(user_id) do
      %Data.User{
        image_24: "image24",
        real_name: "real_name_#{user_id}",
        title: "Mouse",
        user_id: user_id
      }
    end
  end

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

  test "get user info" do
    user_data_fn = fn id ->
      send(self(), {:asked_for_user, id})
      {:ok, %{body: TestHelper.parsed_json_for_endpoint("users.info")}}
    end

    assert Data.get_user_info("user_id", user_data_fn) == %Data.User{
             image_24: "https://avatars.slack-edge.com/2019-03-27/591416725831_abcdef123_24.jpg",
             real_name: "Mickey Mouse",
             title: "Mouse",
             user_id: "user_id"
           }

    assert_received {:asked_for_user, "user_id"}
  end

  test "get replies" do
    replies_data_fn = fn channel_id, message_id ->
      send(self(), {:asked_for_replies, channel_id, message_id})
      {:ok, %{body: TestHelper.parsed_json_for_endpoint("conversations.replies")}}
    end

    replies = Data.get_replies("channel_id", "message_id", replies_data_fn)

    assert Enum.count(replies) == 3
    assert_received({:asked_for_replies, "channel_id", "message_id"})
  end
end
