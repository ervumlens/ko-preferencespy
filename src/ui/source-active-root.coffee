
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
		@children.push new SourceRow @, 'global', 'global'
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
		#https://github.com/Komodo/KomodoEdit/blob/master/src/projects/koIProject.p.idl

		@update =>
			@setCurrentProject partService.currentProject, startup

	setCurrentProject: (project, startup) ->
		addChild = true

		if not project
			# No project, so everyone gets a '-'.
			addChild = false
			for child in @children
				break if child.prefRootKey is 'docStateMRU'
				continue unless child.prefRootKey is 'viewStateMRU'
				child.tag = '-'

		else if not startup
			# We have a project loading after we've already initialized.
			# If we've seen the project before, reset its tag. Otherwise,
			# the new project gets a '+' and everyone else gets a '-'.
			for child in @children
				break if child.prefRootKey is 'docStateMRU'
				continue unless child.prefRootKey is 'viewStateMRU'
				if child.prefKey is project.url
					child.tag = ''
					addChild = false
				else
					child.tag = '-'

		# Else we're starting up and we need a new child here.

		if addChild
			child = new SourceRow @, project.name, 'viewStateMRU', project.url
			child.tag = '+' unless startup
			@children.splice 1, 0, child


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
			@unregisterObserverTopics()
		catch

module.exports = SourceActiveRoot
