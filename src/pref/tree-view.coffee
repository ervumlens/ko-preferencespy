#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'

TreeRow 	= require 'preferencespy/pref/tree-row'
TreeRoot	= require 'preferencespy/pref/tree-root'
Sorter		= require 'preferencespy/pref/sorter'
FilterRules	= require 'preferencespy/pref/filter-rules'

COLID_NAME  = 'preferencespy-namecol'
COLID_VALUE = 'preferencespy-valuecol'
COLID_TYPE  = 'preferencespy-typecol'
COLID_STATE = 'preferencespy-overwrittencol'

nameSorter  = new Sorter COLID_NAME, (a, b) ->
	a.getName() > b.getName()

valueSorter = new Sorter COLID_VALUE, (a, b) ->
	astr = a.getValueString()
	bstr = b.getValueString()
	if astr is bstr
		a.getName() > b.getName()
	else
		astr > bstr

typeSorter  = new Sorter COLID_TYPE, (a, b) ->
	atype = a.getType()
	btype = b.getType()
	if atype is btype
		a.getName() > b.getName()
	else
		atype > btype

stateSorter = new Sorter COLID_STATE, (a, b) ->
	astate = a.getOverwritten()
	bstate = b.getOverwritten()
	if astate is bstate
		a.getName() > b.getName()
	else
		astate > bstate

#A TreeView implements nsITreeView
class TreeView
	sorted: false

	constructor: (prefData) ->
		#Root is a virtual row under which all top-level rows belong.
		@root = new TreeRoot
		prefData.visitNames (name, loader) =>
			new TreeRow name, @root, loader

		@.__defineGetter__ 'rowCount', ->
			@root.visibleRowCount()

	rowAt: (index) ->
		@root.rowAt index

	getCellText: (index, col) ->
		#log.warn "value: #{index}, #{col.id}"
		row = @rowAt index
		row.getText col

	getCellValue: (index, col) ->
		null

	setTree: (treebox) ->
		@treebox = treebox
		@root.treebox = treebox

	isEditable: (index, col) ->
		col.editable

	isContainer: (index) ->
		row = @rowAt index
		row.isContainer()

	isContainerOpen: (index) ->
		row = @rowAt index
		row.isOpen()

	isContainerEmpty: (index) ->
		row = @rowAt index
		row.isContainerEmpty()

	isSeparator: (index) ->
		false

	isSorted: ->
		@sorted

	getLevel: (index) ->
		row = @rowAt index
		row.depth

	hasNextSibling: (index, afterIndex) ->
		@root.hasNextSibling index

	getImgSrc: (index, col) ->
		null

	getRowProperties: (index) ->
		false

	getCellProperties: (index, col) ->
		false

	getColumnProperties: (colId, col) ->
		false

	cycleHeader: (col) ->
		switch col.id
			when COLID_NAME  then @sortByName(col)
			when COLID_VALUE then @sortByValue(col)
			when COLID_TYPE  then @sortByType(col)
			when COLID_STATE then @sortByState(col)

	doSort: (sorter, col) ->
		@root.sort sorter, col
		@sorted = true

	sortByName: (col) ->
		@doSort nameSorter, col

	sortByValue: (col) ->
		@doSort valueSorter, col

	sortByType: (col) ->
		@doSort typeSorter, col

	sortByState: (col) ->
		@doSort stateSorter, col

	getParentIndex: (index) ->
		@root.parentIndex index

	toggleOpenState: (index) ->
		return if @isContainerEmpty index
		row = @rowAt index
		row.toggleOpen()
		@treebox.invalidateRow index

	doSearch: ->
		msg = document.getElementById 'preferencespy-search-message'
		rules = new FilterRules
		result = null

		try
			rules.load()
			result = @root.filter rules
		catch e
			result = "Error: #{e.message}"

		msg.textContent = if typeof result is 'number'
			switch result
				when 0 then 'No matches found.'
				when 1 then '1 match found.'
				else "#{result} matches found."
		else
			result.toString()

module.exports = TreeView
