
{Cc, Ci, Cu} = require 'chrome'

PrefData = require 'preferencespy/ui/pref-data'

log = require('ko/logging').getLogger 'preference-spy'

observerService = Cc["@mozilla.org/observer-service;1"].getService Ci.nsIObserverService
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService
partService = Cc["@activestate.com/koPartService;1"].getService Ci.koIPartService
viewService = Cc["@activestate.com/koViewService;1"].getService Ci.koIViewService

SourceRow = require 'preferencespy/ui/source-row'
SourceRoot = require 'preferencespy/ui/source-root'

class SourceActiveRoot extends SourceRoot
	opened: true
	topics: ['current_project_changed']
	events: ['view_opened', 'view_closed']

	constructor: (view, @window) ->
		super view, 'Active'
		@children.push new SourceRow @, 'global', prefRootKey: 'global'
		#TODO add global and anything open
		@resetCurrentProjects true
		@resetCurrentFiles true
		@resetCurrentEditors true

		@eventListener = (args...) => @handleWindowEvent args...

		@registerListeners()

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

	resetCurrentProjects: (startup) ->

			# Remove the existing project if it's there
			remove = if @children[1]?.project then 1 else 0
			removed = null
			if partService.currentProject
				project = partService.currentProject
				child = new SourceRow @, project.name, prefset: project.prefset
				child.url = project.url
				child.project = true
				removed = @children.splice 1, remove, child
			else
				removed = @children.splice 1, remove

			@view.reindex(removed, true) unless startup
			#child = new SourceRow @, project.name, prefRootKey: 'viewStateMRU, prefKey: project.url
			#child = new SourceRow @, project.name, prefset: project.prefset
			#child.url = project.url
			#child.project = true
			#child.tag = '+' unless startup
			#@children.splice 1, 0, child

			#projectsObject = new Object()
			#countObject = new Object()
			## This is not a good way to find projects.
			#partService.getProjects projectsObject, countObject


	resetCurrentFiles: (startup = false) ->
		# Visit all the active views. Create a node for both
		# the view itself and its underlying file (if it exists).

		countObject = new Object();
		views = viewService.getAllViews '', countObject

		if startup
			for view in views
				log.warn "SourceActiveRoot::resetCurrentFiles: view.uid = #{view.uid}"

		else
			for view in views
				log.warn "SourceActiveRoot::resetCurrentFiles: view.uid = #{view.uid}"

	resetCurrentEditors: (startup = false) ->

	observe: (subject, topic, data) ->
		log.warn "SourceActiveRoot::observe #{topic} (#{data})"
		switch topic
			when 'current_project_changed' then @resetCurrentProjects()

	handleWindowEvent: (event) ->
		log.warn "SourceActiveRoot::handleWindowEvent #{event.type}"

	dispose: ->
		try
			@unregisterListeners()
		catch e
			log.error e

module.exports = SourceActiveRoot
