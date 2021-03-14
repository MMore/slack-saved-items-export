defmodule SlackClientTest do
  alias SSIExport.SlackClient
  alias Support.TestHelper
  use ExUnit.Case

  import ExUnit.CaptureIO
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
    assert {:ok, %Tesla.Env{} = env} = SlackClient.get_saved_items()
    assert env.status == 200
    assert Enum.count(env.body["items"]) == 4
  end

  test "get replies for message" do
    assert {:ok, %Tesla.Env{} = env} = SlackClient.get_replies("channel_id", "message_id")

    assert env.status == 200
    assert Enum.count(env.body["messages"]) == 3
  end

  test "get channel info" do
    assert {:ok, %Tesla.Env{} = env} = SlackClient.get_channel_info("channel_id")

    assert env.status == 200
    assert env.body["channel"]["name"] == "general"
  end

  test "get user info" do
    assert {:ok, %Tesla.Env{} = env} = SlackClient.get_user_info("user_id")

    assert env.status == 200
    assert env.body["user"]["real_name"] == "Mickey Mouse"
  end

  describe "handle response" do
    test "returns ok with response" do
      response = %{body: %{"ok" => true, "result" => "yes"}}

      assert SlackClient.handle_response(response) == {:ok, response}
    end

    test "shows missing_scope error and exits program" do
      response = %{body: %{"ok" => false, "error" => "missing_scope"}}

      assert capture_io(fn ->
               assert SlackClient.handle_response(response, fn -> :halt_program end) ==
                        :halt_program
             end) ==
               "error: used token is not granted the required scope permissions\n"
    end

    test "shows invalid_auth error and exits program" do
      response = %{body: %{"ok" => false, "error" => "invalid_auth"}}

      assert capture_io(fn ->
               assert SlackClient.handle_response(response, fn -> :halt_program end) ==
                        :halt_program
             end) ==
               "error: authentication token is invalid\n"
    end

    test "shows ratelimited error and exits program" do
      response = %{body: %{"ok" => false, "error" => "ratelimited"}}

      assert capture_io(fn ->
               assert SlackClient.handle_response(response, fn -> :halt_program end) ==
                        :halt_program
             end) ==
               "error: request has been ratelimited by Slack\n"
    end

    test "shows unknown error and exits program" do
      response = %{body: %{"ok" => false, "error" => "unknown error"}}

      assert capture_io(fn ->
               assert SlackClient.handle_response(response, fn -> :halt_program end) ==
                        :halt_program
             end) ==
               "error: unknown error\n"
    end
  end
end
