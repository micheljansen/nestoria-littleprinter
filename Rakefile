require 'gettext'
require 'gettext/tools'

# GetText::ErbParser.init(:extnames => ['.rhtml', '.erb'])
desc "Create mo-files"
task :makemo do
  GetText.create_mofiles(true, "po", "locale")
end
desc "Update pot/po files to match new version."
task :updatepo do
  GetText.update_pofiles("template", Dir.glob("{.,**}/*.{rb,erb,rjs}"), "nestoria")
end

