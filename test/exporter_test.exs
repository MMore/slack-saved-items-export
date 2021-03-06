defmodule ExporterTest do
  alias SSIExport.DataAdapter
  alias SSIExport.Exporter
  use ExUnit.Case

  doctest SSIExport.Exporter

  describe "export" do
    test "successfully writes a file" do
      path = Path.join(__DIR__, "testexport.html")
      options = %Exporter.Options{destination_file_path: path}
      response = %{body: Support.TestHelper.parsed_json_for_endpoint("stars.list")}

      assert Exporter.export(
               options,
               fn -> {:ok, response} end,
               fn x -> x end,
               fn items, _ ->
                 items
               end,
               fn _output, path -> {:write_file, "output", path} end
             ) == {:write_file, "output", path}
    end
  end

  test "decorates data structure with some nice html" do
    messages = [
      %DataAdapter.SavedMessage{
        channel_id: "C1VUNGG7L",
        channel_name: "channel_name",
        date_created: 1_614_190_396,
        message_id: "1614163736.005600",
        permalink: "https://example.slack.com/archives/C1VUNGG7L/p1614163736005600",
        replies: [
          %DataAdapter.Reply{
            message_id: "1613766054.045300",
            text: "Looks interesting",
            user: %DataAdapter.User{
              user_id: "UH9T09HMW",
              real_name: "Donald Duck",
              title: "Duck",
              image_24: "image24"
            }
          }
        ],
        text: "A message with replies :smile:",
        user: %DataAdapter.User{
          user_id: "U8S7YRMK2",
          real_name: "Mickey Mouse",
          title: "Mice",
          image_24: "image24"
        }
      }
    ]

    # TODO: improve assertions
    assert Exporter.decorate(messages) =~ ~r(Mickey Mouse)
    assert Exporter.decorate(messages) =~ ~r(example.slack.com)
    assert Exporter.decorate(messages) =~ ~r(message with replies)

    assert Exporter.decorate(messages, true) =~ ~r(img src="image24")
  end
end
