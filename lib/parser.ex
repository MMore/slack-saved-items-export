defmodule SlackStarredExport.Parser do
  alias SlackStarredExport.Data
  alias SlackStarredExport.ChannelStore
  alias SlackStarredExport.UserStore

  def parse_starred_items(items, enricher_fn \\ &enrich_starred_message/1) do
    Enum.filter(items, fn x -> x["type"] == "message" end)
    |> Enum.map(fn m ->
      parse_starred_message(m)
      |> enricher_fn.()
    end)
  end

  defp parse_starred_message(message) do
    %Data.StarredMessage{
      channel_id: message["channel"],
      date_created: DateTime.from_unix!(message["date_create"]),
      message_id: message["message"]["ts"],
      permalink: message["message"]["permalink"],
      text: message["message"]["text"],
      user_id: message["message"]["user"]
    }
  end

  def enrich_starred_message(
        message,
        channel_store \\ ChannelStore,
        user_store \\ UserStore,
        data_mod \\ Data,
        reply_parser_fn \\ &parse_replies/1
      ) do
    channel_name_task = Task.async(channel_store, :get_channel_name, [message.channel_id])
    user_name_task = Task.async(user_store, :get_user_name, [message.user_id])

    replies_task = Task.async(data_mod, :get_replies, [message.channel_id, message.message_id])

    %Data.StarredMessage{
      message
      | channel_name: Task.await(channel_name_task),
        user_name: Task.await(user_name_task),
        replies: reply_parser_fn.(Task.await(replies_task))
    }
  end

  def parse_replies(replies, enricher_fn \\ &enrich_reply/1) do
    # don't show parent message again
    Enum.filter(replies, fn x ->
      x["ts"] != x["thread_ts"]
    end)
    |> Enum.map(fn x ->
      parse_reply(x)
      |> enricher_fn.()
    end)
  end

  defp parse_reply(reply) do
    %Data.Reply{
      text: reply["text"],
      message_id: reply["ts"],
      user_id: reply["user"]
    }
  end

  def enrich_reply(reply, user_store \\ UserStore) do
    user_name_task = Task.async(user_store, :get_user_name, [reply.user_id])

    %Data.Reply{
      reply
      | user_name: Task.await(user_name_task)
    }
  end
end
