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
    slack_host = hd(messages).permalink |> get_host_from_uri()
    generation_datetime = DateTime.utc_now() |> DateTime.truncate(:second)

    SlackStarredExport.ExportView.list_starred_messages(messages, slack_host, generation_datetime)
  end

  @doc """
  Transforms a full URI to the host part.

      iex> Exporter.get_host_from_uri("https://example.slack.com/archives/C1VUNGG7L/p1614163736005600")
      "example.slack.com"
  """
  def get_host_from_uri(uri) do
    URI.parse(uri)
    |> Map.fetch!(:host)
  end

  def write_output_to_file(output, destination_file_path) do
    File.write!(destination_file_path, output)
  end
end
