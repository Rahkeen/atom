fs = require 'fs-plus'
path = require 'path'
KeymapManager = require 'atom-keymap'
CSON = require 'season'
{jQuery} = require 'space-pen'

KeymapManager::onDidLoadBundledKeymaps = (callback) ->
  @emitter.on 'did-load-bundled-keymaps', callback

KeymapManager::loadBundledKeymaps = ->
  @loadKeymap(path.join(@resourcePath, 'keymaps'))
  @emit 'bundled-keymaps-loaded'
  @emitter.emit 'did-load-bundled-keymaps'

KeymapManager::getUserKeymapPath = ->
  if userKeymapPath = CSON.resolve(path.join(@configDirPath, 'keymap'))
    userKeymapPath
  else
    path.join(@configDirPath, 'keymap.cson')

KeymapManager::loadUserKeymap = ->
  userKeymapPath = @getUserKeymapPath()
  return unless fs.isFileSync(userKeymapPath)

  try
    @loadKeymap(userKeymapPath, watch: true, suppressErrors: true)
  catch error
    if error.message.indexOf('Unable to watch path') > -1
      message = """
        Unable to watch path: `keymap.cson`. Make sure you have permissions to
        `~/.atom/keymap.cson`. On linux there are currently problems with watch
        sizes. See [this document][watches] for more info.
        [watches]:https://github.com/atom/atom/blob/master/docs/build-instructions/linux.md#typeerror-unable-to-watch-path
      """
      atom.notifications.addError(message, {detail, dismissable: true})
    else
      detail = error.path
      stack = error.stack
      atom.notifications.addFatalError(error.message, {detail, stack, dismissable: true})

KeymapManager::subscribeToFileReadFailure = ->
  this.onDidFailToReadFile (error) ->
    atom.notifications.addError('Failed to load keymap.cson', {detail: error.message, dismissable: true})

# This enables command handlers registered via jQuery to call
# `.abortKeyBinding()` on the `jQuery.Event` object passed to the handler.
jQuery.Event::abortKeyBinding = ->
  @originalEvent?.abortKeyBinding?()

module.exports = KeymapManager
