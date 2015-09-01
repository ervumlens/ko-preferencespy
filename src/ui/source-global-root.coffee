
{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

SourceRoot = require 'preferencespy/ui/source-root'
PrefSource = require 'preferencespy/ui/pref-source'

class SourceGlobalRoot extends SourceRoot
	loaded: true

	constructor: (view) ->
		super view, 'Global'
		@source = PrefSource.create prefService.prefs

	getPrefSource: (index) ->
		if index is @index
			@source
		else
			null


module.exports = SourceGlobalRoot
