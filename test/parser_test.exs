defmodule ParserTest do
  alias SlackStarredExport.Parser
  use ExUnit.Case

  defmodule TestStore do
    def get_channel_name(channel_id) do
      "channel_name_#{channel_id}"
    end

    def get_user_name(user_id) do
      "user_name_#{user_id}"
    end

    def get_replies(channel_id, message_id) do
      "replies_#{channel_id}_#{message_id}"
    end
  end

  test "filters for messages and parses starred items to a defined data structure" do
    messages =
      File.read!(Path.join([__DIR__, "fixtures", "response_stars.list.json"]))
      |> Jason.decode!()

    assert Parser.parse_starred_items(messages["items"], fn x -> x end) == [
             %SlackStarredExport.Data.StarredMessage{
               channel_id: "C1VUNGG7L",
               channel_name: nil,
               date_created: ~U[2021-02-24 18:13:16Z],
               message_id: "1614163736.005600",
               permalink: "https://example.slack.com/archives/C1VUNGG7L/p1614163736005600",
               replies: [],
               text: "A message without replies :smile:",
               user_id: "U8S7YRMK2",
               user_name: nil
             },
             %SlackStarredExport.Data.StarredMessage{
               channel_id: "C0LV45YRJ",
               channel_name: nil,
               date_created: ~U[2021-02-22 10:09:46Z],
               message_id: "1613748935.045000",
               permalink: "https://example.slack.com/archives/C0LV45YRJ/p1613748935045000",
               replies: [],
               text:
                 "FYI recommending <a href=\"https://retrotool.io\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://retrotool.io</a>\n not very known but free and to the point. Our scrum masters use them to great effect.",
               user_id: "U8S7YRMK2",
               user_name: nil
             }
           ]
  end

  describe "parses message text" do
    test "for basic formatting" do
      assert Parser.parse_message_text("Hey *, how? are_you?!.*") ==
               ~s(Hey <b>, how? are_you?!.</b>)

      assert Parser.parse_message_text("Hey _, how? are_you?!._") ==
               ~s(Hey <i>, how? are_you?!.</i>)

      assert Parser.parse_message_text("Hey ~, how? are_you?!.~") ==
               ~s(Hey <span class="line-through">, how? are_you?!.</span>)
    end

    test "for mentions" do
      assert Parser.parse_message_text("Hey <!channel>!") ==
               ~s(Hey <span class="bg-yellow-600 bg-opacity-75 text-yellow-200">@channel</span>!)

      assert Parser.parse_message_text("Hey <!here>!") ==
               ~s(Hey <span class="bg-yellow-600 bg-opacity-75 text-yellow-200">@here</span>!)

      assert Parser.parse_message_text("Hey <!something_else>!") ==
               ~s(Hey <span class="bg-yellow-600 bg-opacity-75 text-yellow-200">@something_else</span>!)
    end

    test "for URLs" do
      assert Parser.parse_message_text(
               "A text with <http://example.org> url and <https://example.org?a=2>"
             ) ==
               ~s(A text with <a href="http://example.org" target="_blank" class="hover:underline text-gray-500">http://example.org</a> url and <a href="https://example.org?a=2" target="_blank" class="hover:underline text-gray-500">https://example.org?a=2</a>)

      assert Parser.parse_message_text(
               "A text with <http://example.org|Example text_block 2-1> url and <http://example.org/?a=1|http://example.org/?a=1> url"
             ) ==
               ~s(A text with <a href="http://example.org" target="_blank" class="hover:underline text-gray-500">Example text_block 2-1</a> url and <a href="http://example.org/?a=1" target="_blank" class="hover:underline text-gray-500">http://example.org/?a=1</a> url)
    end
  end

  test "enriches message with channel name and user name" do
    message = %SlackStarredExport.Data.StarredMessage{
      channel_id: "C1VUNGG7L",
      date_created: 1_614_190_396,
      message_id: "1614163736.005600",
      text: "A message without replies :smile:",
      user_id: "U8S7YRMK2"
    }

    assert Parser.enrich_starred_message(message, TestStore, TestStore, TestStore, fn x -> x end) ==
             %SlackStarredExport.Data.StarredMessage{
               channel_id: "C1VUNGG7L",
               channel_name: "channel_name_C1VUNGG7L",
               date_created: 1_614_190_396,
               message_id: "1614163736.005600",
               replies: "replies_C1VUNGG7L_1614163736.005600",
               text: "A message without replies :smile:",
               user_id: "U8S7YRMK2",
               user_name: "user_name_U8S7YRMK2"
             }
  end

  test "filters and parses replies to a defined data structure" do
    replies =
      File.read!(Path.join([__DIR__, "fixtures", "response_conversations.replies.json"]))
      |> Jason.decode!()

    assert Parser.parse_replies(replies["messages"], fn x -> x end) == [
             %SlackStarredExport.Data.Reply{
               date_created: ~U[2021-02-19 20:20:54Z],
               message_id: "1613766054.045300",
               text: "<@U8S7YRMK2> Looks interesting, thanks for the recommendation!",
               user_id: "UH9T09HMW"
             },
             %SlackStarredExport.Data.Reply{
               date_created: ~U[2021-02-22 09:43:29Z],
               message_id: "1613987009.008700",
               text:
                 "Can also highly recommend <a href=\"https://metroretro.io/\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://metroretro.io/</a>",
               user_id: "U2WQE893K"
             }
           ]
  end

  test "enriches reply with user name" do
    reply = %SlackStarredExport.Data.Reply{
      message_id: "1613766054.045300",
      text: "<@U8S7YRMK2> Looks interesting, thanks for the recommendation!",
      user_id: "UH9T09HMW"
    }

    assert Parser.enrich_reply(reply, TestStore) ==
             %SlackStarredExport.Data.Reply{
               message_id: "1613766054.045300",
               text: "<@U8S7YRMK2> Looks interesting, thanks for the recommendation!",
               user_id: "UH9T09HMW",
               user_name: "user_name_UH9T09HMW"
             }
  end
end
