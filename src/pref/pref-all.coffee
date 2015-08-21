#https://github.com/Komodo/KomodoEdit/blob/master/src/prefs/koIPrefs.idl
#https://github.com/Komodo/KomodoEdit/blob/d5716aec849a9063572f374f2c8a86007b2d80e5/src/chrome/komodo/content/pref/koPrefWindow.js#L65

log = require('ko/logging').getLogger 'preference-spy'

createCell = (parent, label) ->
	cell = document.createElement 'treecell'
	if label
		cell.setAttribute 'label', label
	parent.appendChild cell
	cell

addItem = (parent, values) ->
	return unless values

	item = document.createElement 'treeitem'
	item.setAttribute 'container', 'true'
	item.setAttribute 'open', 'true'
	parent.appendChild item

	row = document.createElement 'treerow'
	item.appendChild row

	createCell row, values.id
	createCell row, values.value
	createCell row, values.type
	if values.inherited
		cell = createCell row, '✓'

reloadPrefs = (prefset) ->
	root = document.getElementById 'preferencespy-prefs-children'

	#TODO clear root's children

	addPrefs prefset, root

addPrefs = (prefset, root) ->
	allIds = prefset.getAllPrefIds()

	for id in allIds
		inherited = not prefset.hasPrefHere(id)
		type = prefset.getPrefType(id)
		value = switch type
			when 'string' then prefset.getStringPref id
			when 'boolean' then prefset.getBooleanPref id
			when 'long' then prefset.getLongPref id
			when 'double' then prefset.getDoublePref id
			else '(unknown)'

		addItem root, {id, value, type, inherited}

@OnPreferencePageLoading = (prefset) ->
	#log.warn 'PreferenceSpy::OnPreferencePageLoading!'
	context = parent.prefInvokeType

	#TODO If global context, create a treeseparator at the bottom of the list,
	#then move our treeitem below it.

	reloadPrefs prefset

	#addItem root, ['context', context]
	#addItem root, ['prefset?', prefset?]

@PreferenceSpyAll_OnLoad = ->
	#log.warn 'PreferenceSpyAll_OnLoad!'
	parent.initPanel()
