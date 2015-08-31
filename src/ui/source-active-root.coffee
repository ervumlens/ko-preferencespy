
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
	loaded: true
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
		@addChild new SourceRow(@, @createKey('global'), PrefSource.create prefService.prefs)

	initCurrentProjects: ->
		return unless partService.currentProject
		@addChild @createProjectRow partService.currentProject

	initCurrentViews: ->
		countObject = new Object();
		views = viewService.getAllViews '', countObject

		for view in views
			@addChild @createViewRow view

	createKey: (type, obj) ->
		switch type
			when 'global' then 'global:global'
			when 'project' then "project:#{obj.url}"
			when 'view'
				#log.warn "SourceActiveRoot::createKey: view has doc? #{obj.koDoc?}"
				#log.warn "SourceActiveRoot::createKey: view has file? #{obj.koDoc?.file?}"
				#log.warn "SourceActiveRoot::createKey: view has URI? #{obj.koDoc?.file?.URI}"
				#log.warn "SourceActiveRoot::createKey: doc has displayPath? #{obj.koDoc?.displayPath}"

				if obj.koDoc
					if obj.koDoc.file?.URI
						"view:#{obj.koDoc.file.URI}"
					else
						"view:#{obj.koDoc.displayPath}"
				else
					log.warn "SourceActiveRoot::createKey: Cannot create view key without a document!"
					'view:??'
			else
				throw new Error "Cannot create key for type #{type}"

	createViewRow: (view) ->
		new SourceRow(@, @createKey('view', view), PrefSource.create view)

	createProjectRow: (project) ->
		new SourceRow(@, @createKey('project', project), PrefSource.create project)

	observe: (subject, topic, data) ->
		log.warn "SourceActiveRoot::observe #{topic} (#{data})"
		switch topic
			when 'current_project_changed' then @resetCurrentProjects()

	handleWindowEvent: (event) ->
		log.warn "SourceActiveRoot::handleWindowEvent #{event.type}"

		view = event.originalTarget

		switch event.type
			when 'view_opened'
				@addView view
			when 'view_closed'
				@removeView view

	addView: (view) ->
		log.warn "SourceActiveRoot::addView: Adding #{@createKey 'view', view}"
		# Check if the key is already in use by a row.
		# If it is, re-attach. If not, create a new row.

		index = @findChildIndexByKey(@createKey 'view', view)
		if index isnt -1
			child = @getChild index
			child.attach view
			# TODO do this more gracefully
			@view.invalidateRow index
		else
			# Add a new row
			0

	removeView: (view) ->
		if view.koDoc
			key = @createKey('view', view)
			log.warn "SourceActiveRoot::removeView: Removing #{key}"
			child = @getChild @findChildIndexByKey key
			child.detach()
			# TODO do this more gracefully
			@view.invalidateRow index

		else
			# The closed view is essentially worthless because
			# its document is inaccessible. So to handle a remove, we
			# have to compare what we have with what's still open... Yuck!

			openKeys = @createKeysForOpenViews()
			rowKeys = @getKeysForViews()
			removedKeys = rowKeys.filter (key) -> openKeys.indexOf(key) is -1

			for key in removedKeys
				index = @findChildIndexByKey key
				child = @getChild index
				child.detach()
				# TODO do this more gracefully
				@view.invalidateRow index


	createKeysForOpenViews: ->
		countObject = new Object();
		views = viewService.getAllViews '', countObject

		@createKey('view', view) for view in views when view.koDoc?

	getKeysForViews: ->
		keys = []
		for child in @children
			id = child.id
			continue unless id and id.indexOf('view:') is 0
			keys.push id
		keys

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
		super
		try
			@unregisterListeners()
		catch e
			log.error e

module.exports = SourceActiveRoot
