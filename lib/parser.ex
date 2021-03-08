defmodule SlackStarredExport.Parser do
  alias SlackStarredExport.Data
  alias SlackStarredExport.ChannelStore
  alias SlackStarredExport.UserStore

  def parse_starred_items(items) do
    Enum.filter(items, fn x -> x["type"] == "message" end)
    |> Enum.map(fn m ->
      parse_starred_message(m)
      |> enrich_starred_message()
    end)
  end

  def parse_starred_message(message) do
    %Data.StarredMessage{
      channel_id: message["channel"],
      date_created: message["date_create"],
      text: message["message"]["text"],
      user_id: message["message"]["user"],
      message_id: message["message"]["ts"]
    }
  end

  def enrich_starred_message(message) do
    channel_name_task = Task.async(ChannelStore, :get_channel_name, [message.channel_id])
    user_name_task = Task.async(UserStore, :get_user_name, [message.user_id])

    replies_task = Task.async(Data, :get_replies, [message.channel_id, message.message_id])

    %Data.StarredMessage{
      message
      | channel_name: Task.await(channel_name_task),
        user_name: Task.await(user_name_task),
        replies: parse_replies(Task.await(replies_task), message)
    }
  end

  def parse_replies(replies, _message) do
    # don't show parent message again
    Enum.filter(replies, fn x ->
      x["ts"] != x["thread_ts"]
    end)
    |> Enum.map(fn x ->
      parse_reply(x)
      |> enrich_reply()
    end)
  end

  def parse_reply(reply) do
    %Data.Reply{
      text: reply["text"],
      message_id: reply["ts"],
      user_id: reply["user"]
    }
  end

  def enrich_reply(reply) do
    user_name_task = Task.async(UserStore, :get_user_name, [reply.user_id])

    %Data.Reply{
      reply
      | user_name: Task.await(user_name_task)
    }
  end
end
