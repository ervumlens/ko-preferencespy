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

	log.warn "Unknown container type encountered: id = #{container.id}"

	new PreferenceContainer

class PreferenceContainer
	name: '(object)'
	count: 0
	constructor: ->
	isEmpty: ->
		@count is 0

	visitNames: (visitor) ->
		log.warn "Called 'visitNames' on a mystery container"

	getValueForId: (id, type) ->
		switch type
			when 'string' then @container.getStringPref id
			when 'boolean' then @container.getBooleanPref id
			when 'long' then @container.getLongPref id
			when 'double' then @container.getDoublePref id
			when 'object' then extractObjectValue @container.getPref id
			else '(unknown)'

	#This is not universally implemented
	isOverwritten: (id) ->
		false

	fetchValues: (id, target) ->
		#log.warn "Loading #{id}..."
		target.type = @container.getPrefType(id)
		target.overwritten = @isOverwritten id
		isContainer = target.type is 'object'

		if isContainer
			target.value = '(container)'
			target.container = extractObjectValue @container.getPref id
		else
			target.value = @getValueForId id, target.type

class PreferenceSet extends PreferenceContainer
	constructor: (@container) ->
		@allIds = @container.getAllPrefIds()
		@count = @allIds.length
		@name = '(empty)' if @isEmpty()

	getAllRowCount: ->
		return

	visitNames: (visitor) ->
		#log.warn "Called 'visitNames' on a PrefSet with #{@count} prefs"
		for id in @allIds
			visitor id, (args...) => @fetchValues args...

	isOverwritten: (id) ->
		@container.hasPrefHere(id)

class OrderedPreference extends PreferenceContainer
	constructor: (@container) ->
		@count = @container.length
		@name = '(empty)' if @isEmpty()

	visitNames: (visitor) ->
		#log.warn "Called 'visitNames' on a OrderedPrefs with #{@count} prefs"
		for id in [0 ... @count]
			visitor id, (args...) => @fetchValues args...

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
