#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'

TreeRow 	= require 'preferencespy/ui/result-row'
TreeRoot	= require 'preferencespy/ui/result-root'
Sorter		= require 'preferencespy/ui/sorter'
FilterRules	= require 'preferencespy/ui/result-filter-rules'


COLID_NAME  = 'result-namecol'
COLID_VALUE = 'result-valuecol'
COLID_TYPE  = 'result-typecol'
COLID_STATE = 'result-overwrittencol'

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
		# This is flipped from usual because the expected, natural
		# sort order is not the mathematical order.
		astate < bstate

#A TreeView implements nsITreeView
class TreeView
	sorted: false
	sorter: nameSorter

	constructor: ->
		#Root is a virtual row under which all top-level rows belong.
		@root = new TreeRoot
		@rules = new FilterRules

		@.__defineGetter__ 'rowCount', =>
			@visibleRowCount()

		@tree = document.getElementById 'result'
		@tree.view = @

	visibleRowCount: ->
		@root.visibleRowCount()

	clear: (updateUI = true) ->
		@root.dispose()
		@root = new TreeRoot
		@root.treebox = @treebox

		if updateUI
			# Force a UI update
			@filterAndSort @rules, @sorter


	load: (prefData, updateUI = true) ->
		@clear false

		prefData.visitNames (name, loader) =>
			new TreeRow name, @root, loader

		if updateUI
			@filterAndSort @rules, @sorter

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
		#log.warn "ResultView::doSearch"
		result = null

		try
			@rules.load()
			result = @filterAndSort @rules, @sorter
		catch e
			result = "Error: #{e.message}"

		log.warn "ResultView::doSearch -> #{result}"

		if typeof result is 'number'
			switch result
				when 0 then 'No matches found.'
				when 1 then '1 match found.'
				else "#{result} matches found."
		else
			result.toString()

	doSort: (sorter, col) ->

		if @sorter.id is sorter.id
			@sorter.reverse()
		else
			@sorter = sorter.clone()

		@update =>
			@root.sort @sorter, col
			@sorted = true
			@updateColumnSortUI @sorter, col

	filterAndSort: (rules, sorter) ->
		count = 0
		@update =>
			count = @root.filterAndSort rules, sorter
		count

	update: (fn) ->
		if @treebox
			@treebox.beginUpdateBatch()
			try
				fn()
			finally
				@treebox.invalidate()
				@treebox.endUpdateBatch()
		else
			fn()

	updateColumnSortUI: (sorter, col) ->
		return unless col and @tree
		columns = col.columns
		direction = sorter.direction
		@tree.setAttribute 'sortResource', col.id

		#Clear all sort attributes everywhere
		for i in [0 ... columns.length]
			otherCol = columns.getColumnAt(i)
			otherCol.element.removeAttribute 'sortDirection'

		col.element.setAttribute 'sortDirection', direction
		@tree.setAttribute 'sortDirection', direction

	dispose: ->
		@root.dispose()

module.exports = TreeView
