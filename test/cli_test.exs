defmodule CLITest do
  alias SSIExport.Application
  alias SSIExport.CLI
  alias SSIExport.Exporter
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "shows help if no/unknown arguments are given or --help is used" do
    assert capture_io(fn -> CLI.main([]) end) == capture_io(fn -> CLI.print_help() end)
    assert capture_io(fn -> CLI.main(["--help"]) end) == capture_io(fn -> CLI.print_help() end)
    assert capture_io(fn -> CLI.main(["wtf"]) end) == capture_io(fn -> CLI.print_help() end)

    assert capture_io(fn -> CLI.main(["--show-profile-image"]) end) ==
             capture_io(fn -> CLI.print_help() end)
  end

  describe "environment variable is NOT set" do
    test "runs the exporter with the given destination file path" do
      System.delete_env(Application.get_token_environment_variable_name())

      output_file = "export.html"

      assert capture_io(fn ->
               CLI.main(["--output", output_file], fn x -> x end)
             end) ==
               "error: environment variable #{Application.get_token_environment_variable_name()} is not set\n"
    end
  end

  describe "environment variable IS set" do
    setup _context do
      System.put_env(Application.get_token_environment_variable_name(), "123")
      :ok
    end

    test "runs the exporter with the given destination file path and no profile image by default" do
      output_file = "export.html"
      destination_path = Path.expand(output_file)

      assert capture_io(fn ->
               CLI.main(["--output", output_file], fn x -> send(self(), {:options, x}) end)
             end) ==
               ~s(Exporting to "#{destination_path}"...\n...done.\n)

      assert_received {:options,
                       %Exporter.Options{
                         destination_file_path: ^output_file,
                         show_profile_image?: false
                       }}
    end

    test "runs the exporter with the show-profile-image option" do
      output_file = "export.html"

      capture_io(fn ->
        CLI.main(["--output", output_file, "--show-profile-image"], fn x ->
          send(self(), {:options, x})
        end)
      end)

      assert_received {:options,
                       %Exporter.Options{
                         destination_file_path: ^output_file,
                         show_profile_image?: true
                       }}
    end
  end
end
