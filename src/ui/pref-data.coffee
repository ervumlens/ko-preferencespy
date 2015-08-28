{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

extractObjectValue = (container) ->
	try
		ordered = container.QueryInterface Ci.koIOrderedPreference
		return new OrderedPreference ordered
	catch e
		#log.warn e
	try
		prefset = container.QueryInterface Ci.koIPreferenceSet
		return new PreferenceSet prefset
	catch e
		#log.warn e

	try
		container.QueryInterface Ci.koIPreferenceChild
		log.warn "Encountered koIPreferenceChild"
	catch e
		#log.warn e

	try
		cache = container.QueryInterface Ci.koIPreferenceCache
		return new PreferenceCache cache
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

	id: ->
		@container.id

	visitNames: (visitor) ->
		log.warn "Called 'visitNames' on a mystery container"

	# Returns the value for the preference named by the id.
	# `null` is returned if the id is invalid/removed/etc. XXX verify
	# The type for the preference is optional. Pass it if it's
	# known to save looking it up again.
	getValueForId: (id, type) ->
		if not type
			type = @container.getPrefType id

		switch type
			when 'string' then @container.getStringPref id
			when 'boolean' then @container.getBooleanPref id
			when 'long' then @container.getLongPref id
			when 'double' then @container.getDoublePref id
			when 'object' then extractObjectValue @container.getPref id
			when null then null
			else "(unknown type #{type})"

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
			value = @getValueForId id, target.type
			value = '(null)' if value is null

			target.value = value

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

class PreferenceCache extends PreferenceContainer
	constructor: (@container) ->
		@count = @container.length
		@name = '(empty)' if @isEmpty()

	visitNames: (visitor) ->
		e = @container.enumPreferences()
		while e.hasMoreElements()
			prefId = e.getNext().id
			visitor prefId, (id, target) => @fetchValues id, target

	fetchValues: (id, target) ->
		target.type = 'object'
		target.value = '(container)'
		target.container = extractObjectValue @container.getPref(id)

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

	@getContainer: (prefset) ->
		extractObjectValue prefset
