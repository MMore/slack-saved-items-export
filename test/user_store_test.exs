defmodule UserStoreTest do
  alias SSIExport.DataAdapter
  alias SSIExport.UserStore
  use ExUnit.Case

  @user_fake %DataAdapter.User{
    user_id: "user_id",
    real_name: "Mickey Mouse",
    title: "Mouse",
    image_24: "image24"
  }

  defmodule TestDataMod do
    def get_user_info(user_id) do
      send(self(), {:asked_for_user_info, user_id})

      %DataAdapter.User{
        user_id: "user_id",
        real_name: "Mickey Mouse",
        title: "Mouse",
        image_24: "image24"
      }
    end
  end

  test "asks external service for user name if not in cache" do
    assert UserStore.handle_call({:get_user_info, "user_id"}, nil, [], TestDataMod) ==
             {:reply, @user_fake, [{"user_id", @user_fake}]}

    assert_received {:asked_for_user_info, "user_id"}
  end

  test "asks NOT external service for user name if in cache" do
    current_state = [
      {"user_id", @user_fake},
      {"123", %DataAdapter.User{@user_fake | user_id: "123", real_name: "Donald Duck"}}
    ]

    assert UserStore.handle_call(
             {:get_user_info, "user_id"},
             nil,
             current_state,
             TestDataMod
           ) ==
             {:reply, @user_fake, current_state}

    refute_received {:asked_for_user_info, "user_id"}
  end
end
