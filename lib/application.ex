defmodule SSIExport.Application do
  def start(_type, _args) do
    children = [
      {SSIExport.ChannelStore, []},
      {SSIExport.UserStore, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def get_token_environment_variable_name do
    "SLACK_SAVED_ITEMS_EXPORT_OAUTH_TOKEN"
  end
end
