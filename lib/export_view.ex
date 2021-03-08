defmodule SlackStarredExport.ExportView do
  require EEx

  @template_path Path.expand("../templates", __DIR__)

  EEx.function_from_file(:def, :list_starred_messages, Path.join(@template_path, "list.eex"), [
    :messages,
    :slack_host,
    :generation_datetime
  ])

  EEx.function_from_file(:def, :show_reply, Path.join(@template_path, "reply.eex"), [
    :reply
  ])
end
