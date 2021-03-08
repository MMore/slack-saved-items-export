defmodule SlackStarredExport.StarredMessage do
  alias SlackStarredExport.SlackClient

  defstruct channel_id: nil,
            channel_name: nil,
            date_created: nil,
            text: nil,
            user_id: nil,
            user_name: nil,
            thread_id: nil

  def get_channel_name(channel_id) do
    {:ok, response} = SlackClient.get_channel_info(channel_id)

    response.body["channel"]["name"]
  end

  def get_user_name(user_id) do
    {:ok, response} = SlackClient.get_user_info(user_id)

    response.body["user"]["real_name"]
  end
end
