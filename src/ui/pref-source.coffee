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
			log.warn e
	null

class PrefSource
	displayName: '(unknown name)'
	id: '(unknown id)'

	@create: (source) ->
		# Possible arg types: koIProject, koIView, koIPreferenceContainer, {uri, project/file}
		result = if source.QueryInterface
				qiFactory source, ViewSource, ProjectSource, ContainerSource
		else if source.uri
			OfflineProjectSource(source) if source.project
			OfflineFileSource(source) if source.file

		if not result
			throw new Error("Cannot create PrefSource from #{source}")

		result

	visitPrefNames: (visitor) ->
		throw new Error("No container available for #{@id}") unless @container
		@container.visitNames visitor

class ProjectSource extends PrefSource
	@interface: Ci.koIProject

	constructor: (@project) ->
		@displayName = @project.name.replace '.komodoproject', ''
		@container = PrefData.createContainer @project.prefset
		@id = @container.id()
		@url = @project.url

	visitPrefNames: (visitor) ->
		# Projects have two sets of prefs: one for the runtime data and
		# another for offline.
		@container.visitNames visitor, 'view'
		cache = prefService.getPrefs 'viewStateMRU'
		if cache.hasPref @url
			log.warn "Found cache prefs for #{@url}"
			offlineContainer = PrefData.createContainer(cache.getPref @url)
			offlineContainer.visitNames visitor, 'file'
		else
			log.warn "No cache prefs for #{@url}"

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
		cache = prefService.getPrefs 'docStateMRU'
		if cache.hasPref @uri
			log.warn "Found cache prefs for #{@uri}"
			offlineContainer = PrefData.createContainer(cache.getPref @uri)
			offlineContainer.visitNames visitor, 'file'
		else
			log.warn "No cache prefs for #{@uri}"

class OfflineFileSource extends PrefSource
	constructor: (opts) ->
		@id = @uri = opts.uri


class OfflineProjectSource extends PrefSource
	constructor: (opts) ->
		@id = @uri = opts.uri

class ContainerSource extends PrefSource
	@interface: Ci.koIPreferenceContainer

	constructor: (@prefset) ->
		@displayName = @prefset.id
		@container = PrefData.getContainer @prefset
		@id = @container.id()

module.exports = PrefSource
