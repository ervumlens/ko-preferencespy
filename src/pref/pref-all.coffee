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

class ClickTarget
	constructor: (@tree, @event) ->
		switch @event.target.localName
			when 'treechildren'
				box = @tree.treeBoxObject
				cell = row: {}, col: {}, child: {}
				box.getCellAt @event.clientX, @event.clientY, @cell.row, @cell.col, @cell.child
				@click = => @showCellMenu cell
			when 'treecol'
				attributes = @event.target.attributes
				for i in [0 ... attributes.length]
					name = attributes[i].name
					value = attributes[i].value
					log.warn "@event.target.attributes[#{i}] = (#{name},#{value})"

				#@click = => @sortOnColumn @event.target

	click: ->

	sortOnColumn: (col)->
		#do sort
		log.warn "Sorting column..."
		if col.getAttribute('sortActive') is 'true'
			log.warn "Toggling sort..."
			#toggle sorting
			if col.getAttribute('sortDirection') is 'ascending'
				log.warn "Sort descending"
				col.removeAttribute 'sortActive'
				col.removeAttribute 'sortDirection'
				col.removeAttribute 'flex'
				col.setAttribute 'sortActive', 'true'
				col.setAttribute 'sortDirection', 'descending'
			else
				log.warn "Sort ascending"
				col.removeAttribute 'sortActive'
				col.removeAttribute 'sortDirection'
				col.removeAttribute 'flex'
				col.setAttribute 'sortActive', 'true'
				col.setAttribute 'sortDirection', 'ascending'
		else
			#TODO find the active one and deactivate it
			log.warn "New sort column..."
		true

	showCellMenu: (cell)->
		#show select all/copy prompt
		log.warn "Showing context menu..."
		true

@PreferenceSpy_onTreeClicked = (tree, event) ->
	#target = new ClickTarget tree, event
	#target.click()

	#log.warn ">>"
	#log.warn event.target.localName
	#log.warn event.currentTarget.localName
	#log.warn event.originalTarget.localName
	#log.warn event.explicitOriginalTarget.localName
	#log.warn "<<"
	#log.warn "clicked on #{inf.row.value} #{inf.col.value} #{inf.child.value}"

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
