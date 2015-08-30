
{Cc, Ci, Cu} = require 'chrome'

PrefData = require 'preferencespy/ui/pref-data'

log = require('ko/logging').getLogger 'preference-spy'

observerService = Cc["@mozilla.org/observer-service;1"].getService Ci.nsIObserverService
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService
partService = Cc["@activestate.com/koPartService;1"].getService Ci.koIPartService
viewService = Cc["@activestate.com/koViewService;1"].getService Ci.koIViewService

SourceRow = require 'preferencespy/ui/source-row'
SourceRoot = require 'preferencespy/ui/source-root'
PrefSource = require 'preferencespy/ui/pref-source'


class SourceProjectsRoot extends SourceRoot
	constructor: (view) ->
		super view, 'All Projects'

		@prefset = prefService.getPrefs 'viewStateMRU'
		@container = PrefData.createContainer @prefset

	isEmpty: ->
		@container.isEmpty()

	load: ->
		@load = ->

		@container.visitNames (name) =>
			return unless @prefset.hasPref name
			source = PrefSource.create(@prefset.getPref name)
			source.sourceHint = 'file'
			child = new SourceRow @, source

			# Trim the name so that it fits in the tree
			child.name = @trimChildName child.name
			child.name = child.name.replace '.komodoproject', ''
			@addChild child

module.exports = SourceProjectsRoot
