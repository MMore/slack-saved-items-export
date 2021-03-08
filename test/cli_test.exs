defmodule CliTest do
  alias SlackStarredExport.Application
  alias SlackStarredExport.Cli
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "shows help if no/unknown arguments are given or --help is used" do
    assert capture_io(fn -> Cli.main([]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["--help"]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["wtf"]) end) == capture_io(fn -> Cli.print_help() end)
    assert capture_io(fn -> Cli.main(["--output"]) end) == capture_io(fn -> Cli.print_help() end)
  end

  describe "environment variable is NOT set" do
    test "runs the exporter with the given destination file path" do
      System.delete_env(Application.get_token_environment_variable_name())

      output_file = "export.html"

      assert capture_io(fn ->
               Cli.main(["--output", output_file], fn x -> x end)
             end) ==
               "error: environment variable #{Application.get_token_environment_variable_name()} is not set\n"
    end
  end

  describe "environment variable IS set" do
    test "runs the exporter with the given destination file path" do
      System.put_env(Application.get_token_environment_variable_name(), "123")

      output_file = "export.html"
      destination_path = Path.expand(output_file)

      assert capture_io(fn ->
               Cli.main(["--output", output_file], fn x -> send(self(), {:output, x}) end)
             end) ==
               ~s(Exporting to "#{destination_path}"...\n...done.\n)

      assert_received {:output, ^output_file}
    end
  end
end
