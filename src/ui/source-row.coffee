{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

PrefData = require 'preferencespy/ui/pref-data'

class SourceRow
	name: '??'
	tag: ''
	filterable: true
	attached: true
	index: -1

	constructor: (@root, @id, @source) ->
		throw new Error("Cannot create SourceRow without PrefSource object") unless @source
		@name = @source.displayName

	getVisualProperties: ->
		switch @tag
			when '-' then 'removed'
			else ''

	detach: ->
		throw new Error("Cannot detach a detached row") unless @attached
		@attached = false
		@tag = '-'
		@source = @source.detach()

	attach: (obj) ->
		throw new Error("Cannot attach an attached row") if @attached
		@attached = true
		@tag = ''
		@source = @source.attach obj
		@name = @source.displayName

module.exports = SourceRow
