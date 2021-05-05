-- lite-xl 1.16
local core = require "core"

return {
  get_data = function()
    local current_doc = core.active_view.doc
    core.log("discord plugin: python script requested data")
    return {
      doc_title = current_doc.filename,
      folder = "lite-xl-discord" -- for now
    }
  end
}
