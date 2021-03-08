defmodule SlackStarredExport.Exporter do
  alias SlackStarredExport.SlackClient
  alias SlackStarredExport.Parser

  def export() do
    {:ok, response} = SlackClient.get_starred_items()

    Parser.parse_starred_items(response.body["items"])
  end
end
