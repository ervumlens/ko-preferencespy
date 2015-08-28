{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

PrefData = require 'preferencespy/ui/pref-data'

class SourceRow
	constructor: (@root, @name, @prefRootKey, @prefKey = null) ->
	load: ->
		#lazy load the pref container
		rootPrefs = prefService.getPrefs @prefRootKey
		if @prefKey
			@container = PrefData.getContainer rootPrefs.getPref @prefKey
		else
			@container = PrefData.getContainer rootPrefs
		@load = ->
	getPrefContainer: ->
		@load()
		@container

module.exports = SourceRow
