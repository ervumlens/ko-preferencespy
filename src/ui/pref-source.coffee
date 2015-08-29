{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
PrefData = require 'preferencespy/ui/pref-data'

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
		container = @getContainer()
		container.visitNames visitor

	getContainer: ->
		throw new Error("No container available for #{@id}") unless @container
		@container

class ProjectSource extends PrefSource
	@interface: Ci.koIProject

	constructor: (@project) ->
		@displayName = @project.name.replace '.komodoproject', ''
		@container = PrefData.createContainer @project.prefset
		@id = @container.id()

class ViewSource extends PrefSource
	@interface: Ci.koIView

	constructor: (@view) ->
		name = @view.koDoc?.baseName
		@displayName = name or '(new file)'
		@container = PrefData.createContainer @view.prefs
		@id = @container.id()


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
