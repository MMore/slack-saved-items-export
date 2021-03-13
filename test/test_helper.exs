ExUnit.start()

defmodule Support.TestHelper do
  def parsed_json_for_endpoint(endpoint) do
    path = Path.join(__DIR__, "fixtures")

    Path.join(path, "response_#{endpoint}.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
