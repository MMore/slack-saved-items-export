defmodule SlackStarredExport.Application do
  def start(_type, _args) do
    IO.puts("Starting SlackStarredExport application...")

    children = [
      {SlackStarredExport.ChannelStore, []},
      {SlackStarredExport.UserStore, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
