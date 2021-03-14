defmodule SSIExport.ExportView do
  require EEx

  @template_path Path.expand("../templates", __DIR__)

  EEx.function_from_file(:def, :list_saved_messages, Path.join(@template_path, "list.eex"), [
    :messages,
    :slack_host,
    :generation_datetime,
    :show_profile_image?
  ])

  EEx.function_from_file(:def, :show_message, Path.join(@template_path, "message.eex"), [
    :date_created,
    :text,
    :user,
    :channel_type,
    :channel_name,
    :permalink,
    :show_profile_image?
  ])

  EEx.function_from_file(:def, :show_reply, Path.join(@template_path, "reply.eex"), [
    :reply,
    :show_profile_image?
  ])

  EEx.function_from_file(:def, :show_channel, Path.join(@template_path, "channel.eex"), [
    :channel_type,
    :channel_name
  ])
end
