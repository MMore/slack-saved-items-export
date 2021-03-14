# Slack Saved Items Export

[![Elixir CI](https://github.com/MMore/slack-saved-items-export/actions/workflows/elixir.yml/badge.svg)](https://github.com/MMore/slack-saved-items-export/actions/workflows/elixir.yml)

Export your [saved messages in Slack](https://slack.com/intl/en-de/help/articles/360042650274-Save-messages-and-files-) to a neat HTML file - for your own reference or as a simple archive. Don't lose your Slack bookmarks anymore.

## Setup

For running you just need to have [Erlang/OTP](https://medium.com/@brucifi/erlang-quick-install-a3b7fd96947f) installed. It does not require [Elixir](https://elixir-lang.org/install.html) to be installed unless you wanna build it on your own.

Download the [slack-saved-items-export](https://github.com/MMore/slack-saved-items-export/releases) binary.

Alternatively build it with

```
$ mix escript.build
```

## Usage

Create a "[Slack App](https://api.slack.com/authentication/basics)" in your Slack workspace (means basically getting an API token) with the following permissions:
- channels:history
- channels:read
- groups:history
- groups:read
- im:history
- im:read
- mpim:history
- mpim:read
- stars:read
- users:read

After installation you get a [user token](https://api.slack.com/authentication/token-types#user) which starts usually with `xoxp-`. Set this token as environment variable and run the program:

```
export SLACK_SAVED_ITEMS_EXPORT_OAUTH_TOKEN=xoxp-YOUR-TOKEN
./slack-saved-items-export --help
./slack-saved-items-export --output export.html --show-profile-image
```

## Example output

![example](https://user-images.githubusercontent.com/172760/110870228-53744480-82cc-11eb-8400-af95e369f858.png)

## License

Available under the MIT license. See the [LICENSE](LICENSE)
