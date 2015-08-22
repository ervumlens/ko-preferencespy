#https://github.com/Komodo/KomodoEdit/blob/master/src/prefs/koIPrefs.idl
#https://github.com/Komodo/KomodoEdit/blob/d5716aec849a9063572f374f2c8a86007b2d80e5/src/chrome/komodo/content/pref/koPrefWindow.js#L65

log = require('ko/logging').getLogger 'preference-spy'

#{Cc, Ci, Cu} = require 'chrome'
Cc = Components.classes
Ci = Components.interfaces
Cu = Components.utils

createCell = (parent, label) ->
	cell = document.createElement 'treecell'
	if label
		cell.setAttribute 'label', label
	parent.appendChild cell
	cell

addItem = (parent, values) ->
	return unless values
	isObject = values.type is 'object'
	isPopulatedObject = isObject and not values.value.isEmpty()
	item = document.createElement 'treeitem'
	item.setAttribute 'container', 'true'

	if isPopulatedObject
		item.setAttribute 'open', 'false'
	else
		item.setAttribute 'open', 'true'

	parent.appendChild item

	row = document.createElement 'treerow'
	item.appendChild row

	createCell row, values.id.toString()
	createCell row, (if isObject then values.value.name else values.value.toString())
	createCell row, values.type
	if values.overwritten
		cell = createCell row, '✓'

	if isPopulatedObject
		children = document.createElement 'treechildren'
		item.appendChild children

		values.value.addChildren children
		#childItem = document.createElement 'treeitem'
		#children.appendChild childItem
		#
		#childRow = document.createElement 'treerow'
		#childItem.appendChild childRow
		#
		#createCell childRow, 'foobar'
		#createCell childRow, 'blingblong'


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
	getValueForId: (id, type) ->
		switch type
			when 'string' then @container.getStringPref id
			when 'boolean' then @container.getBooleanPref id
			when 'long' then @container.getLongPref id
			when 'double' then @container.getDoublePref id
			when 'object' then extractObjectValue @container.getPref id
			else '(unknown)'

class PreferenceSet extends PreferenceContainer
	constructor: (@container) ->
		@allIds = @container.getAllPrefIds()
		@count = @allIds.length
		@name = '(empty)' if @isEmpty()

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


@OnPreferencePageLoading = (rawPrefset) ->
	#log.warn 'PreferenceSpy::OnPreferencePageLoading!'
	context = parent.prefInvokeType

	#TODO create a treeseparator at the bottom of the list,
	#then move our treeitem below it.

	root = document.getElementById 'preferencespy-prefs-children'
	prefset = new PreferenceSet rawPrefset
	prefset.addChildren root

@PreferenceSpyAll_OnLoad = ->
	#log.warn 'PreferenceSpyAll_OnLoad!'
	parent.initPanel()
