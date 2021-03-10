defmodule SlackStarredExport.Data do
  alias SlackStarredExport.SlackClient

  defmodule StarredMessage do
    defstruct channel_id: nil,
              channel_name: nil,
              date_created: nil,
              message_id: nil,
              permalink: nil,
              text: nil,
              user_id: nil,
              user: nil,
              replies: []
  end

  defmodule Reply do
    defstruct date_created: nil,
              message_id: nil,
              text: nil,
              user_id: nil,
              user: nil
  end

  defmodule User do
    defstruct user_id: nil,
              real_name: nil,
              title: nil,
              image_24: nil
  end

  def get_channel_name(channel_id) do
    {:ok, response} = SlackClient.get_channel_info(channel_id)

    response.body["channel"]["name"]
  end

  def get_user_info(user_id) do
    {:ok, response} = SlackClient.get_user_info(user_id)

    response.body["user"]
  end

  def get_replies(channel_id, message_id) do
    {:ok, response} = SlackClient.get_replies(channel_id, message_id)

    response.body["messages"]
  end
end
