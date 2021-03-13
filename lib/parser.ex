defmodule SSIExport.Parser do
  alias SSIExport.ChannelStore
  alias SSIExport.Data
  alias SSIExport.UserStore

  def parse_saved_items(items, enricher_fn \\ &enrich_saved_message/1) do
    Enum.filter(items, fn x -> x["type"] == "message" end)
    |> Enum.map(fn m ->
      Task.async(fn ->
        parse_saved_message(m)
        |> enricher_fn.()
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
  end

  defp parse_saved_message(message) do
    saved_message = %Data.SavedMessage{
      channel_id: message["channel"],
      date_created: DateTime.from_unix!(message["date_create"]),
      message_id: message["message"]["ts"],
      permalink: message["message"]["permalink"],
      text: parse_message_text(message["message"]["text"]),
      user: %Data.User{user_id: message["message"]["user"]}
    }

    # bot user?
    if saved_message.user.user_id == nil do
      user = %Data.User{saved_message.user | real_name: message["message"]["username"]}
      %Data.SavedMessage{saved_message | user: user}
    else
      saved_message
    end
  end

  def parse_message_text(text, user_store \\ UserStore) do
    parse_basic_formatting(text)
    |> parse_general_mentions()
    |> parse_user_mentions(user_store)
    |> parse_url()
  end

  defp parse_basic_formatting(text) do
    String.replace(
      text,
      ~r/\*([^<>\*]+)\*/,
      ~s(<b>\\1</b>)
    )
    |> String.replace(
      ~r/~([^<>~]+)~/,
      ~s(<span class="line-through">\\1</span>)
    )
    |> String.replace(
      ~r/`([^<>`]+)`/,
      ~s(<span class="bg-gray-200 bg-opacity-75 border-gray-400 border rounded p-0.5 text-pink-500">\\1</span>)
    )
    |> String.replace(
      ~r/<#[[:word:]]+\|([[:word:]-]+)>/,
      ~s(<span class="bg-blue-200 bg-opacity-75 text-blue-400">#\\1</span>)
    )
    |> String.replace(
      "\n",
      "<br />"
    )
  end

  defp parse_general_mentions(text) do
    String.replace(
      text,
      ~r/<!([[:word:]]+)>/,
      ~s(<span class="bg-yellow-300 bg-opacity-75 text-gray-800 font-medium">@\\1</span>)
    )
  end

  defp parse_user_mentions(text, user_store) do
    user_mention_regex = ~r/<@([[:word:]]+)>/

    Regex.scan(user_mention_regex, text, capture: :all_but_first)
    |> Enum.map(fn user_id ->
      Task.async(user_store, :get_user_info, [hd(user_id)])
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> Enum.reduce(text, fn u, acc ->
      String.replace(
        acc,
        "<@#{u.user_id}>",
        ~s(<span class="bg-yellow-300 bg-opacity-75 text-gray-800 font-medium">@#{u.real_name}</span>)
      )
    end)
  end

  defp parse_url(text) do
    String.replace(
      text,
      ~r"<((?:mailto:|https?:\/\/)[^\|>]+)\|([^>]+)>",
      ~s(<a href="\\1" target="_blank" class="hover:underline text-gray-500">\\2</a>)
    )
    |> String.replace(
      ~r"<(https?://[^>]+)>",
      ~s(<a href="\\1" target="_blank" class="hover:underline text-gray-500">\\1</a>)
    )
  end

  def enrich_saved_message(
        %Data.SavedMessage{} = message,
        channel_store \\ ChannelStore,
        user_store \\ UserStore,
        data_mod \\ Data,
        reply_parser_fn \\ &parse_replies/1
      ) do
    channel_name_task = Task.async(channel_store, :get_channel_name, [message.channel_id])

    user_info_task =
      if message.user.real_name == nil do
        Task.async(user_store, :get_user_info, [message.user.user_id])
      else
        nil
      end

    replies_task = Task.async(data_mod, :get_replies, [message.channel_id, message.message_id])

    channel_info = Task.await(channel_name_task, :infinity)

    saved_message = %Data.SavedMessage{
      message
      | channel_name: elem(channel_info, 1),
        channel_type: elem(channel_info, 0),
        replies: reply_parser_fn.(Task.await(replies_task, :infinity))
    }

    if user_info_task != nil do
      %Data.SavedMessage{saved_message | user: Task.await(user_info_task, :infinity)}
    else
      saved_message
    end
  end

  def parse_replies(replies, enricher_fn \\ &enrich_reply/1, user_store \\ UserStore) do
    # don't show parent message again
    Enum.filter(replies, fn x ->
      x["thread_ts"] != nil and x["ts"] != x["thread_ts"]
    end)
    |> Enum.map(fn x ->
      parse_reply(x, user_store)
      |> enricher_fn.()
    end)
  end

  defp parse_reply(reply, user_store) do
    %Data.Reply{
      date_created: convert_slack_timestamp_to_datetime(reply["ts"]),
      message_id: reply["ts"],
      text: parse_message_text(reply["text"], user_store),
      user: %Data.User{user_id: reply["user"]}
    }
  end

  defp convert_slack_timestamp_to_datetime(timestamp) when is_binary(timestamp) do
    String.split(timestamp, ".") |> hd() |> String.to_integer() |> DateTime.from_unix!()
  end

  def enrich_reply(%Data.Reply{} = reply, user_store \\ UserStore) do
    user_info = user_store.get_user_info(reply.user.user_id)

    %Data.Reply{reply | user: user_info}
  end
end
