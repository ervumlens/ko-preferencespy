
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

class SourceActiveRoot extends SourceRoot
	opened: true
	topics: ['current_project_changed']
	events: ['view_opened', 'view_closed']

	constructor: (view, @window) ->
		super view, 'Active'

		@initGlobal()
		@initCurrentProjects()
		@initCurrentViews()

		@eventListener = (args...) => @handleWindowEvent args...

		@registerListeners()

	initGlobal: ->
		@children.push new SourceRow(@, PrefSource.create prefService.prefs)

	initCurrentProjects: ->
		return unless partService.currentProject
		@children.push new SourceRow(@, PrefSource.create partService.currentProject)

	initCurrentViews: ->
		countObject = new Object();
		views = viewService.getAllViews '', countObject

		for view in views
			@children.push new SourceRow(@, PrefSource.create view)

	resetCurrentProjects: ->
	resetCurrentViews: ->

	observe: (subject, topic, data) ->
		log.warn "SourceActiveRoot::observe #{topic} (#{data})"
		switch topic
			when 'current_project_changed' then @resetCurrentProjects()

	handleWindowEvent: (event) ->
		log.warn "SourceActiveRoot::handleWindowEvent #{event.type}"


	registerListeners: ->
		for topic in @topics
			observerService.addObserver @, topic, false

		for event in @events
			@window.addEventListener event, @eventListener, false

	unregisterListeners: ->
		for topic in @topics
			observerService.removeObserver @, topic

		for event in @events
			@window.removeEventListener event, @eventListener

	dispose: ->
		try
			@unregisterListeners()
		catch e
			log.error e

module.exports = SourceActiveRoot
