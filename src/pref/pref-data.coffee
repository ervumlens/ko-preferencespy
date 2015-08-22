{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

extractObjectValue = (container) ->
	try
		ordered = container.QueryInterface Ci.koIOrderedPreference
		return new OrderedPreference container
	catch e
		#log.warn e
	try
		prefset = container.QueryInterface Ci.koIPreferenceSet
		return new PreferenceSet prefset
	catch e
		#log.warn e

	new PreferenceContainer

class PreferenceContainer
	name: '(object)'
	count: 0
	constructor: ->
	isEmpty: ->
		@count is 0
	addChildren: (root) ->
	visitNames: (visitor) ->
	getValueForId: (id, type) ->
		switch type
			when 'string' then @container.getStringPref id
			when 'boolean' then @container.getBooleanPref id
			when 'long' then @container.getLongPref id
			when 'double' then @container.getDoublePref id
			when 'object' then extractObjectValue @container.getPref id
			else '(unknown)'

	fetchValues: (id, target) ->
		#log.warn "Loading #{id}..."
		target.type = @container.getPrefType(id)
		target.overwritten = @container.hasPrefHere(id)
		isContainer = target.type is 'object'

		if isContainer
			target.value = '(container)'
			target.container = extractObjectValue @container.getPref id
		else
			target.value = @getValueForId id, target.type
			target.getContainer = null

class PreferenceSet extends PreferenceContainer
	constructor: (@container) ->
		@allIds = @container.getAllPrefIds()
		@count = @allIds.length
		@name = '(empty)' if @isEmpty()

	getAllRowCount: ->
		return

	visitNames: (visitor) ->
		for id in @allIds
			visitor id, (args...) => @fetchValues args...

	addChildren: (root) ->
		for id in @allIds
			overwritten = @container.hasPrefHere(id)
			type = @container.getPrefType(id)
			value = @getValueForId id, type
			addItem root, {id, value, type, overwritten}

class OrderedPreference extends PreferenceContainer
	constructor: (@container) ->
		@count = @container.length
		@name = '(empty)' if @isEmpty()

	addChildren: (root) ->
		id = 0
		loop
			break unless id < @count
			overwritten = false
			type = @container.getPrefType(id)
			value = @getValueForId id, type
			addItem root, {id, value, type, overwritten}
			++id

module.exports = class PrefData
	meta: []

	constructor: (rootPrefSet) ->
		@root = new PreferenceSet rootPrefSet

	addChildren: (root) ->
		@root.addChildren root

	filterAndSort: ->
		#copy self, apply filter, sort

	visitNames: (visitor) ->
		@root.visitNames visitor
