defmodule SlackStarredExport.Parser do
  alias SlackStarredExport.StarredMessage
  alias SlackStarredExport.ChannelStore
  alias SlackStarredExport.UserStore

  def parse_starred_messages(messages) do
    Enum.map(messages, fn m ->
      parse_starred_message(m)
      |> enrich_starred_message()
    end)
  end

  def parse_starred_message(message) do
    %StarredMessage{
      channel_id: message["channel"],
      date_created: message["date_create"],
      text: message["message"]["text"],
      user_id: message["message"]["user"],
      thread_id: message["message"]["ts"]
    }
  end

  def enrich_starred_message(message) do
    channel_name_task = Task.async(ChannelStore, :get_channel_name, [message.channel_id])
    user_name_task = Task.async(UserStore, :get_user_name, [message.user_id])

    %StarredMessage{
      message
      | channel_name: Task.await(channel_name_task),
        user_name: Task.await(user_name_task)
    }
  end
end
