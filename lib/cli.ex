defmodule SlackStarredExport.Cli do
  def main(args) do
    args
    |> parse_args()
    |> process_args()
  end

  defp parse_args(args) do
    {params, _, _} = OptionParser.parse(args, strict: [help: :boolean, token: :string])
    params
  end

  defp process_args([]) do
    print_help()
  end

  defp process_args(help: true) do
    print_help()
  end

  defp process_args(args) do
    IO.puts(inspect(args))
  end

  defp print_help() do
    IO.puts("Export your starred items in Slack\n")
    IO.puts("  --token <token> - Use the OAuth Token from an installed Slack app.")
    IO.puts("  --help - Print this help message")
  end
end
