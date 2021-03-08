defmodule CliTest do
  alias SlackStarredExport.Cli
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "shows help if no/unknown arguments are given or --help is used" do
    assert capture_io(fn -> Cli.main([]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["--help"]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["wtf"]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["--output"]) end) == capture_io(fn -> Cli.print_help() end)
  end

  test "runs the exporter with the given destination file path" do
    output_file = "export.html"
    destination_path = Path.expand(output_file)

    assert capture_io(fn ->
             Cli.main(["--output", output_file], fn x -> send(self(), {:output, x}) end)
           end) ==
             ~s(Exporting to "#{destination_path}"...\n...done.\n)

    assert_received {:output, ^output_file}
  end
end
