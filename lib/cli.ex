defmodule SlackStarredExport.Cli do
  alias SlackStarredExport.Application
  alias SlackStarredExport.Exporter

  @token_environment_variable_name Application.get_token_environment_variable_name()

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
    validate_environment_variable()
    |> do_export(destination_file_path, exporter_fn)
  end

  defp process_args(args, _) do
    IO.puts(inspect(args))
  end

  defp validate_environment_variable() do
    System.get_env(@token_environment_variable_name)
  end

  defp do_export(nil, _, _) do
    IO.puts("error: environment variable #{@token_environment_variable_name} is not set")
    # System.halt(1)
  end

  defp do_export(_, destination_file_path, exporter_fn) do
    expanded_path = Path.expand(destination_file_path)
    IO.puts(~s(Exporting to "#{expanded_path}"...))
    exporter_fn.(destination_file_path)
    IO.puts("...done.")
  end

  def print_help() do
    IO.puts("Export your starred items in Slack as HTML\n")
    IO.puts("  --output <file-path> - Set the destination file path.")
    IO.puts("  --help - Print this help message\n")
    IO.puts("Before running set the environment variable #{@token_environment_variable_name}.")
  end
end
