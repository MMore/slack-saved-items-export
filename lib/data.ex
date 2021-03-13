defmodule SSIExport.Data do
  alias SSIExport.SlackClient
  alias SSIExport.UserStore

  defmodule SavedMessage do
    defstruct channel_id: nil,
              channel_name: nil,
              channel_type: nil,
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

  def get_channel_info(
        channel_id,
        get_data_fn \\ &SlackClient.get_channel_info/1,
        user_store \\ UserStore
      ) do
    {:ok, response} = get_data_fn.(channel_id)

    channel_info_type(response.body["channel"], user_store)
  end

  defp channel_info_type(%{"is_channel" => true} = info, _) do
    {:public, info["name"]}
  end

  defp channel_info_type(%{"is_group" => true} = info, _) do
    {:private_group, info["name"]}
  end

  defp channel_info_type(%{"is_im" => true} = info, user_store) do
    user = user_store.get_user_info(info["user"])
    {:im, user.real_name}
  end

  defp channel_info_type(%{} = info, _) do
    raise("error: channel_info_type unknown (#{inspect(info)})")
  end

  def get_user_info(user_id, get_data_fn \\ &SlackClient.get_user_info/1) do
    {:ok, response} = get_data_fn.(user_id)

    user_info = response.body["user"]

    %User{
      user_id: user_id,
      real_name: user_info["real_name"],
      title: user_info["profile"]["title"],
      image_24: user_info["profile"]["image_24"]
    }
  end

  def get_replies(channel_id, message_id, get_replies_fn \\ &SlackClient.get_replies/2) do
    {:ok, response} = get_replies_fn.(channel_id, message_id)

    response.body["messages"]
  end
end
