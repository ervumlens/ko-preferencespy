{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
PrefData = require 'preferencespy/ui/pref-data'
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

qiFactory = (obj, ctors...) ->
	for ctor in ctors
		iface = ctor.interface
		try
			return new ctor(obj.QueryInterface iface)
		catch e
			# Exceptions are expected. Don't log them unless
			# you (as in, "me") are sure there's a problem here.

			#log.warn e
	null

class PrefSource
	displayName: '(unknown name)'
	id: '(unknown id)'
	sourceHint: 'view'

	@create: (source) ->
		# Possible arg types: koIProject, koIView, koIPreferenceContainer
		result = if source.QueryInterface
				qiFactory source, ViewSource, ProjectSource, ContainerSource

		if not result
			throw new Error("Cannot create PrefSource from #{source}")

		result

	visitPrefNames: (visitor) ->
		throw new Error("No container available for #{@id}") unless @container
		@container.visitNames visitor, @sourceHint

	detach: ->
		throw new Error "Cannot call detach on preference source (#{@.__proto__.constructor.name}) #{@id}"

	attach: ->
		throw new Error "Cannot call attach on preference source (#{@.__proto__.constructor.name}) #{@id}"

class ProjectSource extends PrefSource
	@interface: Ci.koIProject

	constructor: (@project) ->
		@displayName = @project.name.replace '.komodoproject', ''
		@container = PrefData.createContainer @project.prefset
		@id = @container.id()
		@url = @project.url
		cache = prefService.getPrefs 'viewStateMRU'
		if cache.hasPref @url
			#log.warn "Found cache prefs for #{@url}"
			@offlineContainer = PrefData.createContainer(cache.getPref @url)
		else
			#log.warn "No cache prefs for #{@url}"

	visitPrefNames: (visitor) ->
		# Projects have two sets of prefs: one for the runtime data and
		# another for offline.
		@container.visitNames visitor, 'view'
		if @offlineContainer
			@offlineContainer.visitNames visitor, 'file'

	detach: ->
		url = @url
		new OfflineSource @, ->
			return unless url
			cache = prefService.getPrefs 'viewStateMRU'
			if cache.hasPref url
				#log.warn "Found cache prefs for #{@url}"
				PrefData.createContainer(cache.getPref url)
			else
				null

class ViewSource extends PrefSource
	@interface: Ci.koIView

	constructor: (@view) ->
		name = @view.koDoc?.baseName
		@displayName = name or '(new file)'
		@container = PrefData.createContainer @view.prefs
		@id = @container.id()
		@uri = @view.koDoc?.file?.URI

	visitPrefNames: (visitor) ->
		# Projects have two sets of prefs: one for the runtime data and
		# another for offline.
		@container.visitNames visitor, 'view'

		# Apparently the `docStateMRU` preferences map to
		# the view preferences whenever there is a view using
		# that particular URI. Just skip this part since there's
		# no point in clogging up the UI with duplicates.

	detach: ->
		uri = @uri
		new OfflineSource @, ->
			return unless uri
			cache = prefService.getPrefs 'docStateMRU'
			if cache.hasPref uri
				PrefData.createContainer(cache.getPref uri)
			else
				null

class ContainerSource extends PrefSource
	@interface: Ci.koIPreferenceContainer

	constructor: (@prefset) ->
		@displayName = @prefset.id
		@container = PrefData.getContainer @prefset
		@id = @container.id()

class OfflineSource extends PrefSource
	sourceHint: 'file'

	constructor: (source, @loader) ->
		@id = source.id
		@displayName = source.displayName

	load: ->
		return unless @loader
		@container = @loader()
		@loader = null

	visitPrefNames: (visitor) ->
		@load()
		return unless @container
		super

	attach: (obj) ->
		PrefSource.create obj

module.exports = PrefSource
