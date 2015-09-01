
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
		global = new SourceRow(@, @createKey('global'), PrefSource.create prefService.prefs)
		global.filterable = false
		@addChild global

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
		switch topic
			when 'current_project_changed' then @resetCurrentProjects()

	invalidateChild: (index) ->
		@view.invalidateRow @index + index + 1

	resetCurrentProjects: ->
		# The best we can do here is operate on `currentProject`
		# even though multiple projects may be open. We end up visually "closing"
		# projects because of this. :frown:

		if partService.currentProject
			# Attach the project if it already has as row.
			# Otherwise, give it a row after global.

			newProject = partService.currentProject
			matchedIndex = -1
			key = @createKey 'project', newProject

			found = @findChild key, (child, index) =>
				# The project already has a row. Reattach it.
				child.attach newProject
				@invalidateChild index

			if not found
				# Not listed, so add it after global.
				# Global is never filtered out, so this works fine.
				child = @createProjectRow(newProject)
				child.markAsAdded()
				@addChild child, 1
				@view.reindex()
				@view.rowCountChanged @index + 2, 1
		else
			# Detach all projects
			@findAllProjects (project, index) =>
				project.detach()
				@invalidateChild index


	handleWindowEvent: (event) ->
		view = event.originalTarget

		switch event.type
			when 'view_opened'
				@addView view
			when 'view_closed'
				@removeView view

	addView: (view) ->
		# Check if the key is already in use by a row.
		# If it is, re-attach. If not, create a new row.

		key = @createKey 'view', view
		found = @findChild key, (child, index) =>
			child.attach view
			@invalidateChild index

		if not found
			# Add a new row
			child = @createViewRow view
			child.markAsAdded()
			@addChild child
			@view.reindex()
			@view.rowCountChanged @index + @getChildCount() - 1, 1

	findChild: (key, visitor) ->
		found = false
		for child, index in @children
			if child.id is key
				found = true
				visitor child, index
				break
		found

	findAllProjects: (visitor) ->
		found = false
		for child, index in @children
			id = child.id
			if id and id.indexOf('project:') is 0
				found = true
				visitor child, index
		found


	removeViewWithDoc: (view) ->
		key = @createKey('view', view)
		@findChild key, (child, index) =>
			child.detach()
			@invalidateChild index

	removeViewWithoutDoc: (view) ->
		# The closed view is essentially worthless because
		# its document is inaccessible. So to handle a remove, we
		# have to compare what we have with what's still open... Yuck!

		openKeys = @createKeysForOpenViews()
		rowKeys = @getKeysForOpenViewRows()
		removedKeys = rowKeys.filter (key) -> openKeys.indexOf(key) is -1

		for key in removedKeys
			@findChild key, (child, index) =>
				child.detach()
				@invalidateChild index

	removeView: (view) ->
		if view.koDoc
			@removeViewWithDoc view
		else
			@removeViewWithoutDoc view

	createKeysForOpenViews: ->
		countObject = new Object();
		views = viewService.getAllViews '', countObject

		@createKey('view', view) for view in views when view.koDoc?

	getKeysForOpenViewRows: ->
		keys = []
		for child in @children
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
