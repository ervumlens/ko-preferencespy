
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

class SourceFilesRoot extends SourceRoot
	offlineIndex: 0

	constructor: (view) ->
		super view, 'All Files'

		@prefset = prefService.getPrefs 'docStateMRU'
		@container = PrefData.createContainer @prefset

	isEmpty: ->
		return super if @loaded
		@container.isEmpty()

	load: ->
		super
		@load = ->

		@container.visitNames (name) =>
			return unless @prefset.hasPref name
			source = PrefSource.create(@prefset.getPref name)
			source.sourceHint = 'file'
			child = new SourceRow @, name, source
			# Trim the name so that it fits in the tree
			child.name = @trimChildName child.name
			@addChild child

	hasMoreOfflineWork: ->
		not @disposed and
		not @loaded and
		not @container.isEmpty() and
		@offlineIndex < @container.count

	offlineStep: ->
		return 100 unless @hasMoreOfflineWork()

		# Prevent a full load from occurring
		@load = ->

		step = 100 / @container.count

		name = @container.getName @offlineIndex
		++@offlineIndex

		if @prefset.hasPref name
			source = PrefSource.create(@prefset.getPref name)
			source.sourceHint = 'file'
			child = new SourceRow @, name, source
			# Trim the name so that it fits in the tree
			child.name = @trimChildName child.name
			@addChild child

		step * @offlineIndex

module.exports = SourceFilesRoot
