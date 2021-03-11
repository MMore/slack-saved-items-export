defmodule SSIExport.SlackClient do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://slack.com/api")

  plug(Tesla.Middleware.Headers, [
    {"Content-Type", "application/x-www-form-urlencoded"},
    {"Authorization", "Bearer #{get_token_from_environment()}"}
  ])

  plug(Tesla.Middleware.JSON)

  def get_saved_items() do
    get("/stars.list")
  end

  def get_replies(channel_id, message_id) do
    get("/conversations.replies", query: [channel: channel_id, ts: message_id])
  end

  def get_channel_info(channel_id) do
    get("/conversations.info", query: [channel: channel_id])
  end

  def get_user_info(user_id) do
    get("/users.info", query: [user: user_id])
  end

  defp get_token_from_environment() do
    System.get_env(SSIExport.Application.get_token_environment_variable_name())
  end
end
