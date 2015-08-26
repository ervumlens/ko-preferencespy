
{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

PrefData = require 'preferencespy/pref/pref-data'

class PrefScope
	constructor: (@scope, @prefset) ->
		@container = PrefData.getContainer @prefset
		@observerService = @prefset.prefObserverService
		if @observerService
			@observerService.addObserver @, '', true

	dispose: ->
		if @observerService
			@observerService.removeObserver @, ''

	observe: (prefset, topic, data) ->

		localContainer = PrefData.getContainer prefset

		value = localContainer.getValueForId topic

		if value?.QueryInterface?
			#The value is an object, just call it such
			value = '(object)'

		msg = if value isnt null then "now \"#{value}\"" else 'removed'
		log.warn "Preference changed (#{@scope}): \"#{topic}\" is #{msg}"
		log.warn 'Stack trace: \n' + @createTrace()

	createTrace: ->
		stack = new Error().stack
		parts = stack.split '\n'
		parts = parts.map (part) -> '\t' + part
		parts.join '\n'

class PrefScopeGroup extends PrefScope
	constructor: ->
		super
		@idToChild = {}

	loadChildren: ->
		@idToChild = {}
		@container.visitNames (id) =>
			return unless @prefset.hasPref id
			@addChild id

	addChild: (id) ->
		prefs = @prefset.getPref id
		child = new PrefScope id, prefs
		@idToChild[id] = child
		#log.warn "Adding scope #{rootName} -> #{id}"

	removeChild: (id) ->
		child = @idToChild[id]
		child.dispose()
		delete @idToChild[id]

	disposeChildren: ->
		for id, child of @idToChild
			child.dispose()

		@idToChild = {}

	observe: (subject, id, data) ->
		super
		hasPref = @prefset.hasPref(id)
		hasChild = @idToChild[id]

		if hasPref and not hasChild
			@addChild id
		else if not hasPref and hasChild
			@removeChild id

	dispose: ->
		super
		@disposeChildren()

class PrefLogger
	loggingGlobal: false
	loggingProjects: false
	loggingFiles: false

	constructor: ->
		@prefService = Cc["@activestate.com/koPrefService;1"].
                getService(Ci.koIPrefService);

	toggleGlobal: ->
		if @loggingGlobal
			@globalScope.dispose() if @globalScope
			@globalScope = null
		else
			@globalScope = @createScopeFromRootPref 'global'
		@loggingGlobal = not @loggingGlobal

	toggleProjects: ->
		if @loggingProjects
			@projectScopes.dispose() if @projectScopes
			@projectScopes = null
		else
			@projectScopes = @createGroupFromRootPref 'viewStateMRU'
			@projectScopes.loadChildren()

		@loggingProjects = not @loggingProjects

	toggleFiles: ->
		if @loggingFiles
			@fileScopes.dispose() if @fileScopes
			@fileScopes = null
		else
			@fileScopes = @createGroupFromRootPref 'docStateMRU'
			@fileScopes.loadChildren()

		@loggingFiles = not @loggingFiles

	createScopeFromRootPref: (name) ->
		new PrefScope name, @prefService.getPrefs(name)

	createGroupFromRootPref: (name) ->
		new PrefScopeGroup name, @prefService.getPrefs(name)

	dispose: ->
		@globalScope.dispose() if @globalScope
		@projectScopes.dispose() if @projectScopes
		@fileScopes.dispose() if @fileScopes


module.exports = PrefLogger
