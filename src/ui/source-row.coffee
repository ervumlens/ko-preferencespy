{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

PrefData = require 'preferencespy/ui/pref-data'

class SourceRow
	constructor: (@root, @name, opts) ->
		for k, v of opts
			@[k] = v

	load: ->
		if @prefRootKey
			#lazy load the pref container
			rootPrefs = prefService.getPrefs @prefRootKey
			if @prefKey
				@container = PrefData.getContainer rootPrefs.getPref @prefKey
			else
				@container = PrefData.getContainer rootPrefs
		else if @prefset
			@container = PrefData.getContainer @prefset
		else
			log.warn "Cannot load source row #{@name}: no preference data configured."

		@load = ->
	getPrefContainer: ->
		@load()
		@container

module.exports = SourceRow
