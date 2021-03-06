{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

extractObjectValue = (container) ->
	try
		ordered = container.QueryInterface Ci.koIOrderedPreference
		return new OrderedPreference ordered

	try
		prefset = container.QueryInterface Ci.koIPreferenceSet
		return new PreferenceSet prefset

	try
		container.QueryInterface Ci.koIPreferenceChild
		log.warn "Encountered koIPreferenceChild"

	try
		cache = container.QueryInterface Ci.koIPreferenceCache
		return new PreferenceCache cache

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

	visitNames: (visitor, sourceHint) ->
		log.warn "Called 'visitNames' on a mystery container"

	getName: (index) ->
		log.warn "Called 'getName' on a mystery container"

	buildNameArray: (name) ->
		# Gather up the ancestor names, if they exist

		names = [@id()]
		names.push(name) if name
		parent = @container.container
		while parent
			names.unshift parent.id
			parent = parent.container

		names

	addObserver: (observer) ->
		observerService = @container.prefObserverService

		if observerService
			observerService.addObserver observer, '', false

	removeObserver: (observer) ->
		observerService = @container.prefObserverService

		if observerService
			observerService.removeObserver observer, ''

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

	getTypeForId: (id) ->
		@container.getPrefType id

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

	visitNames: (visitor, sourceHint = null) ->
		#log.warn "Called 'visitNames' on a PrefSet with #{@count} prefs"
		for id in @allIds
			visitor id, sourceHint, (args...) => @fetchValues args...

	getName: (index) ->
		@allIds[index]

	isOverwritten: (id) ->
		@container.hasPrefHere(id)

class OrderedPreference extends PreferenceContainer
	constructor: (@container) ->
		@count = @container.length
		@name = '(empty)' if @isEmpty()

	visitNames: (visitor, sourceHint = null) ->
		#log.warn "Called 'visitNames' on a OrderedPrefs with #{@count} prefs"
		for id in [0 ... @count]
			visitor id, sourceHint, (args...) => @fetchValues args...

	getName: (index) ->
		index

class PreferenceCache extends PreferenceContainer
	constructor: (@container) ->
		@count = @container.length
		@name = '(empty)' if @isEmpty()

	loadIds: ->
		@ids = []
		e = @container.enumPreferences()
		while e.hasMoreElements()
			@ids.push e.getNext().id

		@loadIds = ->

	visitNames: (visitor, sourceHint = null) ->
		@loadIds()

		for prefId in @ids
			visitor prefId, sourceHint, (id, target) => @fetchValues id, target

	getName: (index) ->
		@loadIds()
		@ids[index]

	fetchValues: (id, target) ->
		target.type = 'object'
		target.value = '(container)'
		target.container = extractObjectValue @container.getPref(id)

class PrefData
	meta: []

	@createContainer: (prefset) ->
		extractObjectValue prefset

	@getContainer: (prefset) ->
		extractObjectValue prefset

module.exports = PrefData
