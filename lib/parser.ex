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
      text: parse_message_text(message["message"]["text"]),
      user_id: message["message"]["user"]
    }
  end

  def parse_message_text(text) do
    parse_basic_formatting(text)
    |> parse_mentions()
    |> parse_url()
  end

  defp parse_basic_formatting(text) do
    String.replace(
      text,
      ~r/\*([^<>]+)\*/,
      ~s(<b>\\1</b>)
    )
    |> String.replace(
      ~r/_([^<>]+)_/,
      ~s(<i>\\1</i>)
    )
    |> String.replace(
      ~r/~([^<>]+)~/,
      ~s(<span class="line-through">\\1</span>)
    )
  end

  defp parse_mentions(text) do
    String.replace(
      text,
      ~r/<!([[:word:]]+)>/,
      ~s(<span class="bg-yellow-600 bg-opacity-75 text-yellow-200">@\\1</span>)
    )
  end

  defp parse_url(text) do
    String.replace(
      text,
      ~r"<(https?://[^\|>]+)\|([^>]+)>",
      ~s(<a href="\\1" target="_blank" class="hover:underline text-gray-500">\\2</a>)
    )
    |> String.replace(
      ~r"<(https?://[^>]+)>",
      ~s(<a href="\\1" target="_blank" class="hover:underline text-gray-500">\\1</a>)
    )
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
      date_created: convert_slack_timestamp_to_datetime(reply["ts"]),
      message_id: reply["ts"],
      text: parse_message_text(reply["text"]),
      user_id: reply["user"]
    }
  end

  defp convert_slack_timestamp_to_datetime(timestamp) when is_binary(timestamp) do
    String.split(timestamp, ".") |> hd() |> String.to_integer() |> DateTime.from_unix!()
  end

  def enrich_reply(reply, user_store \\ UserStore) do
    user_name_task = Task.async(user_store, :get_user_name, [reply.user_id])

    %Data.Reply{
      reply
      | user_name: Task.await(user_name_task)
    }
  end
end
