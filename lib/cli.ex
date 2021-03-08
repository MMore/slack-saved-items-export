defmodule SlackStarredExport.Cli do
  alias SlackStarredExport.Exporter

  def main(args, exporter_fn \\ &Exporter.export/1) do
    args
    |> parse_args()
    |> process_args(exporter_fn)
  end

  defp parse_args(args) do
    {params, _, _} = OptionParser.parse(args, strict: [help: :boolean, output: :string])
    params
  end

  defp process_args([], _) do
    print_help()
  end

  defp process_args([help: true], _) do
    print_help()
  end

  defp process_args([output: destination_file_path], exporter_fn) do
    expanded_path = Path.expand(destination_file_path)
    IO.puts(~s(Exporting to "#{expanded_path}"...))
    exporter_fn.(destination_file_path)
    IO.puts("...done.")
  end

  defp process_args(args, _) do
    IO.puts(inspect(args))
  end

  def print_help() do
    IO.puts("Export your starred items in Slack as HTML\n")
    IO.puts("  --output <file-path> - Set the destination file path.")
    IO.puts("  --help - Print this help message\n")
    IO.puts("Before running set the environment variable SLACK_STARRED_EXPORT_OAUTH_TOKEN.")
  end
end
