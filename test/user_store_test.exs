defmodule UserStoreTest do
  alias SlackStarredExport.UserStore
  use ExUnit.Case

  defmodule TestDataMod do
    def get_user_name(user_id) do
      send(self(), :asked_for_user_name)
      "user_name_#{user_id}"
    end
  end

  test "asks external service for user name if not in cache" do
    assert UserStore.handle_call({:get_user_name, "user_id"}, nil, [], TestDataMod) ==
             {:reply, "user_name_user_id", [{"user_id", "user_name_user_id"}]}

    assert_received :asked_for_user_name
  end

  test "asks NOT external service for user name if in cache" do
    current_state = [{"user_id", "user_name_user_id"}, {"123", "user_123"}]

    assert UserStore.handle_call(
             {:get_user_name, "user_id"},
             nil,
             current_state,
             TestDataMod
           ) ==
             {:reply, "user_name_user_id", current_state}

    refute_received :asked_for_user_name
  end
end
