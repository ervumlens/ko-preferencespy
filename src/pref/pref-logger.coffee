
{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

PrefData = require 'preferencespy/pref/pref-data'

class PrefScope
	constructor: (@scope, prefset) ->
		@observerService = prefset.prefObserverService
		@observerService.addObserver @, '', true
		@container = PrefData.getContainer prefset

	dispose: ->
		@observerService.removeObserver @, ''

	observe: (subject, topic, data) ->
		value = @container.getValueForId topic

		if value.QueryInterface?
			#The values is an object, just call it such
			value = '(object)'

		log.warn "Preference changed (#{@scope}): #{topic} is now \"#{value}\""
		#log.warn "Subject is nsISupports: #{subject.QueryInterface?}"

class PrefLogger
	loggingGlobal: false
	loggingProjects: false
	loggingFiles: false

	constructor: ->
		@prefService = Cc["@activestate.com/koPrefService;1"].
                getService(Ci.koIPrefService);
		@projectScopes = []
		@fileScopes = []

	toggleGlobal: ->
		if @loggingGlobal
			@globalScope.dispose() if @globalScope
			@globalScope = null
		else
			@globalScope = @createScopeFromRootPref 'global'
		@loggingGlobal = not @loggingGlobal

	toggleProjects: ->
		if @loggingProjects
			@projectScopes.forEach (scope) -> scope.dispose()
			@projectScopes = []
		else
			@createScopesFromChildPrefs 'viewStateMRU', @projectScopes
		@loggingProjects = not @loggingProjects

	reloadProjects: ->
		return unless @loggingProjects
		@createScopesFromChildPrefs 'viewStateMRU', @projectScopes

	toggleFiles: ->
		if @loggingFiles
			@fileScopes.forEach (scope) -> scope.dispose()
			@fileScopes = []
		else
			@createScopesFromChildPrefs 'docStateMRU', @fileScopes
		@loggingFiles = not @loggingFiles

	reloadFiles: ->
		return unless @loggingFiles
		@createScopesFromChildPrefs 'docStateMRU', @fileScopes

	createScopeFromRootPref: (name) ->
		new PrefScope name, @prefService.getPrefs(name)

	createScopesFromChildPrefs: (rootName, target) ->
		rootPrefs = @prefService.getPrefs rootName
		rootContainer = PrefData.getContainer rootPrefs
		rootContainer.visitNames (id) =>
			if rootPrefs.hasPref id
				prefs = rootPrefs.getPref id
				target.push new PrefScope id, prefs
				#log.warn "Adding scope #{rootName} -> #{id}"

	dispose: ->
		@globalScope.dispose() if @globalScope
		@projectScopes.forEach (scope) -> scope.dispose()
		@fileScopes.forEach (scope) -> scope.dispose()


module.exports = PrefLogger
