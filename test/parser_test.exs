defmodule ParserTest do
  alias SSIExport.Data
  alias SSIExport.Parser
  use ExUnit.Case

  defmodule TestStore do
    def get_channel_name(channel_id) do
      {:public, "channel_name_#{channel_id}"}
    end

    def get_user_info(user_id) do
      %SSIExport.Data.User{
        image_24: "image24",
        real_name: "real_name_#{user_id}",
        title: "Mouse",
        user_id: user_id
      }
    end

    def get_replies(channel_id, message_id) do
      "replies_#{channel_id}_#{message_id}"
    end
  end

  test "filters for messages and parses saved items to a defined data structure" do
    messages =
      File.read!(Path.join([__DIR__, "fixtures", "response_stars.list.json"]))
      |> Jason.decode!()

    assert Parser.parse_saved_items(messages["items"], fn x -> x end) == [
             %Data.SavedMessage{
               channel_id: "C1VUNGG7L",
               channel_name: nil,
               date_created: ~U[2021-02-24 18:13:16Z],
               message_id: "1614163736.005600",
               permalink: "https://example.slack.com/archives/C1VUNGG7L/p1614163736005600",
               replies: [],
               text: "A message without replies :smile:",
               user_id: "U8S7YRMK2",
               user: nil
             },
             %Data.SavedMessage{
               channel_id: "C0LV45YRJ",
               channel_name: nil,
               date_created: ~U[2021-02-22 10:09:46Z],
               message_id: "1613748935.045000",
               permalink: "https://example.slack.com/archives/C0LV45YRJ/p1613748935045000",
               replies: [],
               text:
                 "FYI recommending <a href=\"https://retrotool.io\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://retrotool.io</a><br /> not very known but free and to the point. Our scrum masters use them to great effect.",
               user_id: "U8S7YRMK2",
               user: nil
             }
           ]
  end

  describe "parses message text" do
    test "for basic formatting" do
      assert Parser.parse_message_text("Hey *, how? are_you?!.* and *test*", TestStore) ==
               ~s(Hey <b>, how? are_you?!.</b> and <b>test</b>)

      assert Parser.parse_message_text("Hey ~, how? are_you?!.~ and ~test~", TestStore) ==
               ~s(Hey <span class="line-through">, how? are_you?!.</span> and <span class="line-through">test</span>)

      assert Parser.parse_message_text("Hey `, how? are_you?!.` and `code`", TestStore) ==
               ~s(Hey <span class="bg-gray-200 bg-opacity-75 border-gray-400 border rounded p-0.5 text-pink-500">, how? are_you?!.</span> and <span class="bg-gray-200 bg-opacity-75 border-gray-400 border rounded p-0.5 text-pink-500">code</span>)

      assert Parser.parse_message_text("Channel <#C1VUNGG7L|ch_an-test>!", TestStore) ==
               ~s(Channel <span class="bg-blue-200 bg-opacity-75 text-blue-400">#ch_an-test</span>!)

      assert Parser.parse_message_text(
               "Hey guys!\nHow are you?\n\nAll the best\n&amp; have a great weekend!\n\nMickey",
               TestStore
             ) ==
               ~s(Hey guys!<br />How are you?<br /><br />All the best<br />&amp; have a great weekend!<br /><br />Mickey)
    end

    test "for general mentions" do
      assert Parser.parse_message_text("Hey <!channel>!", TestStore) ==
               ~s(Hey <span class="bg-yellow-300 bg-opacity-75 text-gray-800 font-medium">@channel</span>!)

      assert Parser.parse_message_text("Hey <!here>!", TestStore) ==
               ~s(Hey <span class="bg-yellow-300 bg-opacity-75 text-gray-800 font-medium">@here</span>!)

      assert Parser.parse_message_text("Hey <!something_else>!", TestStore) ==
               ~s(Hey <span class="bg-yellow-300 bg-opacity-75 text-gray-800 font-medium">@something_else</span>!)
    end

    test "for user mentions" do
      assert Parser.parse_message_text("Hey <@U8S7YRMK2>!", TestStore) ==
               ~s(Hey <span class=\"bg-yellow-300 bg-opacity-75 text-gray-800 font-medium\">@real_name_U8S7YRMK2</span>!)
    end

    test "for URLs" do
      assert Parser.parse_message_text(
               "A text with <http://example.org> url and <https://example.org?a=2>",
               TestStore
             ) ==
               ~s(A text with <a href="http://example.org" target="_blank" class="hover:underline text-gray-500">http://example.org</a> url and <a href="https://example.org?a=2" target="_blank" class="hover:underline text-gray-500">https://example.org?a=2</a>)

      assert Parser.parse_message_text(
               "A text with <http://example.org|Example text_block 2-1> url and <http://example.org/?a=1|http://example.org/?a=1> url",
               TestStore
             ) ==
               ~s(A text with <a href="http://example.org" target="_blank" class="hover:underline text-gray-500">Example text_block 2-1</a> url and <a href="http://example.org/?a=1" target="_blank" class="hover:underline text-gray-500">http://example.org/?a=1</a> url)

      assert Parser.parse_message_text(
               "<https://example.de/bd_18/__58.html>",
               TestStore
             ) ==
               ~s(<a href=\"https://example.de/bd_18/__58.html\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://example.de/bd_18/__58.html</a>)

      assert Parser.parse_message_text(
               "<https://example.de/fad/us_upl/pdf/pm/20/17-PM-Nach_ScII_D_Eigt.pdf|https://example.de/fad/us_upl/pdf/pm/20/17-PM-Nach_ScII_D_Eigt.pdf>",
               TestStore
             ) ==
               ~s(<a href=\"https://example.de/fad/us_upl/pdf/pm/20/17-PM-Nach_ScII_D_Eigt.pdf\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://example.de/fad/us_upl/pdf/pm/20/17-PM-Nach_ScII_D_Eigt.pdf</a>)
    end
  end

  test "enriches message with channel name and user info" do
    message = %Data.SavedMessage{
      channel_id: "C1VUNGG7L",
      date_created: 1_614_190_396,
      message_id: "1614163736.005600",
      text: "A message without replies :smile:",
      user_id: "U8S7YRMK2"
    }

    assert Parser.enrich_saved_message(message, TestStore, TestStore, TestStore, fn x -> x end) ==
             %Data.SavedMessage{
               channel_id: "C1VUNGG7L",
               channel_name: "channel_name_C1VUNGG7L",
               channel_type: :public,
               date_created: 1_614_190_396,
               message_id: "1614163736.005600",
               replies: "replies_C1VUNGG7L_1614163736.005600",
               text: "A message without replies :smile:",
               user_id: "U8S7YRMK2",
               user: %Data.User{
                 user_id: "U8S7YRMK2",
                 real_name: "real_name_U8S7YRMK2",
                 title: "Mouse",
                 image_24: "image24"
               }
             }
  end

  describe "replies" do
    test "filters and parses them to a defined data structure" do
      replies =
        File.read!(Path.join([__DIR__, "fixtures", "response_conversations.replies.json"]))
        |> Jason.decode!()

      assert Parser.parse_replies(replies["messages"], fn x -> x end, TestStore) == [
               %Data.Reply{
                 date_created: ~U[2021-02-19 20:20:54Z],
                 message_id: "1613766054.045300",
                 text:
                   "<span class=\"bg-yellow-300 bg-opacity-75 text-gray-800 font-medium\">@real_name_U8S7YRMK2</span> Looks interesting, thanks for the recommendation!",
                 user_id: "UH9T09HMW"
               },
               %Data.Reply{
                 date_created: ~U[2021-02-22 09:43:29Z],
                 message_id: "1613987009.008700",
                 text:
                   "Can also highly recommend <a href=\"https://metroretro.io/\" target=\"_blank\" class=\"hover:underline text-gray-500\">https://metroretro.io/</a>",
                 user_id: "U2WQE893K"
               }
             ]
    end

    test "filters them out if it's not a thread" do
      replies =
        File.read!(
          Path.join([__DIR__, "fixtures", "response_conversations.replies_no_thread.json"])
        )
        |> Jason.decode!()

      assert Parser.parse_replies(replies["messages"], fn x -> x end, TestStore) == []
    end
  end

  test "enriches reply with user name" do
    reply = %Data.Reply{
      message_id: "1613766054.045300",
      text: "<@U8S7YRMK2> Looks interesting, thanks for the recommendation!",
      user_id: "UH9T09HMW"
    }

    assert Parser.enrich_reply(reply, TestStore) ==
             %Data.Reply{
               message_id: "1613766054.045300",
               text: "<@U8S7YRMK2> Looks interesting, thanks for the recommendation!",
               user_id: "UH9T09HMW",
               user: %Data.User{
                 user_id: "UH9T09HMW",
                 real_name: "real_name_UH9T09HMW",
                 title: "Mouse",
                 image_24: "image24"
               }
             }
  end
end
