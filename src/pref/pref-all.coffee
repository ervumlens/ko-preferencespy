#https://github.com/Komodo/KomodoEdit/blob/master/src/prefs/koIPrefs.idl
#https://github.com/Komodo/KomodoEdit/blob/d5716aec849a9063572f374f2c8a86007b2d80e5/src/chrome/komodo/content/pref/koPrefWindow.js#L65
#https://stackoverflow.com/questions/21148975/what-event-am-i-supposed-to-capture-to-catch-checkbox-changes-in-a-xul-tree
#https://dev.mozilla.jp/localmdc/localmdc_5738.html

PRIMARY_CLICK = 0
SECONDARY_CLICK = 2

log = require('ko/logging').getLogger 'preference-spy'
TreeView = require 'preferencespy/pref/tree-view'
PrefData = require 'preferencespy/pref/pref-data'

#{Cc, Ci, Cu} = require 'chrome'
Cc = Components.classes
Ci = Components.interfaces
Cu = Components.utils

@OnPreferencePageLoading = (rawPrefset) ->
	#log.warn 'PreferenceSpy::OnPreferencePageLoading!'
	context = parent.prefInvokeType

	#TODO create a treeseparator at the bottom of the list,
	#then move our treeitem below it.

	prefData = new PrefData(rawPrefset)
	tree = document.getElementById 'preferencespy-tree'
	tree.view = new TreeView prefData

	#root = document.getElementById 'preferencespy-prefs-children'
	#prefData.addChildren root

	#prefset = new PreferenceSet rawPrefset
	#prefset.addChildren root

@PreferenceSpyAll_OnLoad = ->
	#log.warn 'PreferenceSpyAll_OnLoad!'
	parent.initPanel()
