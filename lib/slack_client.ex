defmodule SSIExport.SlackClient do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://slack.com/api")

  plug(Tesla.Middleware.Headers, [
    {"Content-Type", "application/x-www-form-urlencoded"},
    {"Authorization", "Bearer #{get_token_from_environment()}"}
  ])

  plug(Tesla.Middleware.JSON)

  def get_saved_items() do
    {:ok, response} = get("/stars.list")

    handle_response(response)
  end

  def get_replies(channel_id, message_id) do
    {:ok, response} = get("/conversations.replies", query: [channel: channel_id, ts: message_id])

    handle_response(response)
  end

  def get_channel_info(channel_id) do
    {:ok, response} = get("/conversations.info", query: [channel: channel_id])

    handle_response(response)
  end

  def get_user_info(user_id) do
    {:ok, response} = get("/users.info", query: [user: user_id])

    handle_response(response)
  end

  def handle_response(response, halt_fn \\ &halt_program/0) do
    body = response.body

    if body["ok"] do
      {:ok, response}
    else
      handle_error(body["error"], halt_fn)
    end
  end

  defp handle_error("missing_scope", halt_fn) do
    IO.puts("error: used token is not granted the required scope permissions")
    halt_fn.()
  end

  defp handle_error("invalid_auth", halt_fn) do
    IO.puts("error: authentication token is invalid")
    halt_fn.()
  end

  defp handle_error("ratelimited", halt_fn) do
    IO.puts("error: request has been ratelimited by Slack")
    halt_fn.()
  end

  defp handle_error(reason, halt_fn) do
    IO.puts("error: #{reason}")
    halt_fn.()
  end

  defp halt_program do
    System.halt(1)
  end

  defp get_token_from_environment() do
    System.get_env(SSIExport.Application.get_token_environment_variable_name())
  end
end
