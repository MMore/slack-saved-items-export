defmodule SSIExport.CLI do
  alias SSIExport.Application
  alias SSIExport.Exporter

  @token_environment_variable_name Application.get_token_environment_variable_name()

  def main(args, exporter_fn \\ &Exporter.export/1) do
    args
    |> parse_args()
    |> process_args(exporter_fn)
  end

  defp parse_args(args) do
    {params, _, _} =
      OptionParser.parse(args,
        strict: [help: :boolean, output: :string, show_profile_image: :boolean]
      )

    params
  end

  defp process_args([output: destination_file_path], exporter_fn) do
    process_args([output: destination_file_path, show_profile_image: false], exporter_fn)
  end

  defp process_args(
         [output: destination_file_path, show_profile_image: show_profile_image?],
         exporter_fn
       ) do
    validate_environment_variable()
    |> do_export(
      %Exporter.Options{
        destination_file_path: destination_file_path,
        show_profile_image?: show_profile_image?
      },
      exporter_fn
    )
  end

  defp process_args([], _), do: print_help()
  defp process_args([help: true], _), do: print_help()

  # like --show-profile-image without --output
  defp process_args(_, _), do: print_help()

  defp validate_environment_variable() do
    System.get_env(@token_environment_variable_name)
  end

  defp do_export(nil, _, _) do
    IO.puts("error: environment variable #{@token_environment_variable_name} is not set")
    # System.halt(1)
  end

  defp do_export(_, %Exporter.Options{} = options, exporter_fn) do
    expanded_path = Path.expand(options.destination_file_path)
    IO.puts(~s(Exporting to "#{expanded_path}"...))
    exporter_fn.(options)
    IO.puts("...done.")
  end

  def print_help() do
    IO.puts("Export your saved items in Slack as HTML.\n")
    IO.puts("Before running set the environment variable #{@token_environment_variable_name}.\n")

    IO.puts(
      "  --show-profile-image - Show a profile image next to each profile name (default=false)."
    )

    IO.puts("  --output <file-path> - Set the destination file path.")
    IO.puts("  --help - Print this help message\n")
  end
end
