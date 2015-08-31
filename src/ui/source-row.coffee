{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService

PrefData = require 'preferencespy/ui/pref-data'

class SourceRow
	name: '??'
	tag: ''

	constructor: (@root, @id, @source) ->
		throw new Error("Cannot create SourceRow without PrefSource object") unless @source
		@name = @source.displayName

	getVisualProperties: ->
		switch @tag
			when '-' then 'removed'
			when '+' then 'added'
			else ''

	markAsAdded: ->
		@tag = '+'

	detach: ->
		@tag = '-'
		@source = @source.detach()

	attach: (obj) ->
		@tag = ''
		@source = @source.attach obj
		@name = @source.displayName

module.exports = SourceRow
