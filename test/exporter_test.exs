defmodule ExporterTest do
  alias SSIExport.Data
  alias SSIExport.Exporter
  use ExUnit.Case
  doctest SSIExport.Exporter

  test "decorates data structure with some nice html" do
    messages = [
      %Data.SavedMessage{
        channel_id: "C1VUNGG7L",
        channel_name: "channel_name",
        date_created: 1_614_190_396,
        message_id: "1614163736.005600",
        permalink: "https://example.slack.com/archives/C1VUNGG7L/p1614163736005600",
        replies: [
          %Data.Reply{
            message_id: "1613766054.045300",
            text: "Looks interesting",
            user_id: "UH9T09HMW",
            user: %Data.User{
              user_id: "UH9T09HMW",
              real_name: "Donald Duck",
              title: "Duck",
              image_24: "image24"
            }
          }
        ],
        text: "A message with replies :smile:",
        user_id: "U8S7YRMK2",
        user: %Data.User{
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
  end
end
