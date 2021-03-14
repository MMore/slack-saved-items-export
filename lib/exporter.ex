defmodule SSIExport.Exporter do
  alias SSIExport.SlackClient
  alias SSIExport.Parser

  defmodule Options do
    defstruct destination_file_path: nil, show_profile_image?: false
  end

  def export(
        %Options{} = options,
        get_saved_items_fn \\ &SlackClient.get_saved_items/0,
        parser_fn \\ &Parser.parse_saved_items/1,
        decorate_fn \\ &decorate/2,
        write_file_fn \\ &write_output_to_file/2
      ) do
    {:ok, response} = get_saved_items_fn.()

    parser_fn.(response.body["items"])
    |> decorate_fn.(options.show_profile_image?)
    |> write_file_fn.(options.destination_file_path)
  end

  def decorate(messages, show_profile_image? \\ false) do
    slack_host = hd(messages).permalink |> get_host_from_uri()
    generation_datetime = DateTime.utc_now() |> DateTime.truncate(:second)

    SSIExport.ExportView.list_saved_messages(
      messages,
      slack_host,
      generation_datetime,
      show_profile_image?
    )
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
