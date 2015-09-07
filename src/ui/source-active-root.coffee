
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
	initializing: true
	topics: ['current_project_changed']
	events: ['view_opened', 'view_closed']

	constructor: (view, @window) ->
		super view, 'Active'

		@initCurrentProjects()
		@initCurrentViews()

		@eventListener = (args...) => @handleWindowEvent args...

		@registerListeners()

		@initializing = false

	initCurrentProjects: ->
		return unless partService.currentProject
		@addChild @createProjectRow partService.currentProject

	initCurrentViews: ->
		countObject = new Object()
		views = viewService.getAllViews '', countObject

		for view in views
			@addChild @createViewRow view

	createKey: (type, obj) ->
		switch type
			when 'project' then "project:#{obj.url}"
			when 'view'
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

	clearSelection: ->
		@view.clearSelection()

	observe: (subject, topic, data) ->
		switch topic
			when 'current_project_changed'
				@resetCurrentProjects()
				@clearSelection()

	addChild: (child, index) ->
		super
		if not @initializing
			@view.reindex()
			if @isOpen() and child.index isnt -1
				log.warn "SourceActiveRoot::rowCountChanged: #{child.index}"
				@view.rowCountChanged child.index, 1

	invalidateChild: (child) ->
		if child.index isnt -1
			@view.invalidateRow child.index

	detachChild: (child) ->
		if child.attached
			child.detach()
			@invalidateChild child

	attachChild: (child, obj) ->
		child.attach obj
		@invalidateChild child

	resetCurrentProjects: ->
		# The best we can do here is operate on `currentProject`
		# even though multiple projects may be open. We end up visually "closing"
		# projects because of this. :frown:

		# Detach all projects for starters. This prevents
		# goofy scenarios like "we just set the current project to itself".
		@visitAllProjects (project) =>
			@detachChild project

		if partService.currentProject
			# Attach the project if it already has as row.
			# Otherwise, insert a new top row.

			newProject = partService.currentProject
			matchedIndex = -1
			key = @createKey 'project', newProject

			found = @findChild key, (child) =>
				# The project already has a row. Reattach it.
				@attachChild child, newProject

			if not found
				# Not listed, so add it first.
				child = @createProjectRow(newProject)
				@addChild child, 0


	handleWindowEvent: (event) ->
		view = event.originalTarget

		switch event.type
			when 'view_opened'
				@addView view
				@clearSelection()
			when 'view_closed'
				@removeView view
				@clearSelection()

	addView: (view) ->
		# Check if the key is already in use by a row.
		# If it is, re-attach. If not, create a new row.

		key = @createKey 'view', view
		found = @findChild key, (child) =>
			@attachChild child, view

		if not found
			# Add a new row
			child = @createViewRow view
			@addChild child

	findChild: (key, visitor) ->
		found = false
		for child in @allChildren
			if child.id is key
				found = true
				visitor child
				break
		found

	visitAllProjects: (visitor) ->
		count = 0
		for child in @allChildren
			id = child.id
			if id and id.indexOf('project:') is 0
				found = true
				visitor child
				++count
		count

	removeViewWithDoc: (view) ->
		key = @createKey('view', view)
		@findChild key, (child) =>
			@detachChild child

	removeViewWithoutDoc: (view) ->
		# The closed view is essentially worthless because
		# its document is inaccessible. So to handle a remove, we
		# have to compare what we have with what's still open... Yuck!

		openKeys = @createKeysForOpenViews()
		rowKeys = @getKeysForOpenViewRows()
		removedKeys = rowKeys.filter (key) -> openKeys.indexOf(key) is -1

		for key in removedKeys
			@findChild key, (child) =>
				@detachChild child

	removeView: (view) ->
		if view.koDoc
			@removeViewWithDoc view
		else
			@removeViewWithoutDoc view

	createKeysForOpenViews: ->
		countObject = new Object()
		views = viewService.getAllViews '', countObject

		@createKey('view', view) for view in views when view.koDoc?

	getKeysForOpenViewRows: ->
		keys = []
		for child in @allChildren
			id = child.id
			if child.tag isnt '-' and id and id.indexOf('view:') is 0
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
