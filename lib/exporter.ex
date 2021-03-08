defmodule SlackStarredExport.Exporter do
  alias SlackStarredExport.SlackClient
  alias SlackStarredExport.Parser

  def export() do
    {:ok, response} = SlackClient.get_starred_items()

    response.body["items"]
    |> Enum.filter(fn x -> x["type"] == "message" end)
    |> Parser.parse_starred_messages()
  end
end
