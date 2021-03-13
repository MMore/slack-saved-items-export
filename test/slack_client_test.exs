defmodule SlackClientTest do
  alias Support.TestHelper
  use ExUnit.Case

  import Tesla.Mock

  setup do
    mock(fn
      %{method: :get, url: "https://slack.com/api/stars.list"} ->
        %Tesla.Env{
          status: 200,
          body: TestHelper.parsed_json_for_endpoint("stars.list")
        }

      %{method: :get, url: "https://slack.com/api/conversations.replies"} ->
        %Tesla.Env{
          status: 200,
          body: TestHelper.parsed_json_for_endpoint("conversations.replies")
        }

      %{method: :get, url: "https://slack.com/api/conversations.info"} ->
        %Tesla.Env{
          status: 200,
          body: TestHelper.parsed_json_for_endpoint("conversations.info_channel")
        }

      %{method: :get, url: "https://slack.com/api/users.info"} ->
        %Tesla.Env{
          status: 200,
          body: TestHelper.parsed_json_for_endpoint("users.info")
        }
    end)

    :ok
  end

  test "get saved items" do
    assert {:ok, %Tesla.Env{} = env} = SSIExport.SlackClient.get_saved_items()
    assert env.status == 200
    assert Enum.count(env.body["items"]) == 3
  end

  test "get replies for message" do
    assert {:ok, %Tesla.Env{} = env} =
             SSIExport.SlackClient.get_replies("channel_id", "message_id")

    assert env.status == 200
    assert Enum.count(env.body["messages"]) == 3
  end

  test "get channel info" do
    assert {:ok, %Tesla.Env{} = env} = SSIExport.SlackClient.get_channel_info("channel_id")

    assert env.status == 200
    assert env.body["channel"]["name"] == "general"
  end

  test "get user info" do
    assert {:ok, %Tesla.Env{} = env} = SSIExport.SlackClient.get_user_info("user_id")

    assert env.status == 200
    assert env.body["user"]["real_name"] == "Mickey Mouse"
  end
end
