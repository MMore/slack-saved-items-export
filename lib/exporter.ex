defmodule SlackStarredExport.Exporter do
  alias SlackStarredExport.SlackClient
  alias SlackStarredExport.Parser

  def export(destination_file_path) do
    {:ok, response} = SlackClient.get_starred_items()

    Parser.parse_starred_items(response.body["items"])
    |> decorate()
    |> write_output_to_file(destination_file_path)
  end

  def decorate(messages) do
    SlackStarredExport.ExportView.list_starred_messages(messages)
  end

  def write_output_to_file(output, destination_file_path) do
    File.write!(destination_file_path, output)
  end
end
