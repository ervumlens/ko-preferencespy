
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

		@container.visitNames (name) =>
			return unless @prefset.hasPref name
			child = new SourceRow(@, PrefSource.create @prefset.getPref name)

			# Trim the name so that it fits in the tree

			trimFrom = child.name.lastIndexOf '/'
			if trimFrom != -1
				child.name = child.name[trimFrom + 1 .. -1]

			child.name = child.name.replace '.komodoproject', ''

			@addChild child

module.exports = SourceProjectsRoot
