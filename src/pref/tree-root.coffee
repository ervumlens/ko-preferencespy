
log = require('ko/logging').getLogger 'preference-spy'

TreeRow = require 'preferencespy/pref/tree-row'
Sorter = require 'preferencespy/pref/sorter'

class TreeRoot extends TreeRow
	allRows: []
	sorter: new Sorter null, -> false

	constructor: ->
		@root = @
		@isRoot = true

	index: ->
		-1

	addChild: (childRow) ->
		super
		@allRows.push childRow

	clearChildren: ->
		super
		@allRows = []

	visibleRowCount: ->
		@allRows.length

	rowAt: (index) ->
		@allRows[index]

	isOpen: ->
		true

	open: ->
	close: ->

	parentIndex: (index) ->
		@rowAt(index).parentIndex()

	insertChildren: (row) ->
		#Insert the children of the given row into @allRows
		inserted = row.childCount()
		index = row.index()

		newRows = row.children
		for i in [0 ... inserted]
			@allRows.splice index + 1 + i, 0, newRows[i]

		@treebox.rowCountChanged index + 1, inserted

	removeChildren: (row) ->
		#remove the children of the given row from @allRows
		removed = row.childCount()
		index = row.index()

		@allRows.splice index + 1, removed
		@treebox.rowCountChanged index + 1, -removed

	hasNextSibling: (index) ->
		row = @rowAt index
		row.nextSibling?

	sort: (sorter, col) ->
		direction = null
		if @sorter.id is sorter.id
			@sorter.reverse()
			direction = if @sorter.reversed then 'descending' else 'ascending'
		else
			@sortCol = col
			@sorter = sorter.clone()
			direction = 'ascending'

		@treebox.beginUpdateBatch()
		try
			super @sorter
		catch e
			log.error "Problem sorting: " + e
			log.exception e
		finally
			@updateColumnSortUI col, direction
			@treebox.endUpdateBatch()

	updateColumnSortUI: (col, direction) ->
		return unless col
		tree = document.getElementById 'preferencespy-tree'
		columns = col.columns
		tree.setAttribute 'sortResource', col.id

		#Clear all sort attributes everywhere
		for i in [0 ... columns.length]
			otherCol = columns.getColumnAt(i)
			otherCol.element.removeAttribute 'sortDirection'

		col.element.setAttribute 'sortDirection', direction
		tree.setAttribute 'sortDirection', direction

	filter: (rules) ->
		@filterAndSort rules, @sorter, true

	filterAndSort: (rules, sorter, recycleSorter) ->

		if not recycleSorter
			if @sorter.id is sorter.id
				@sorter.reverse()
			else
				@sorter = sorter.clone()

		direction = if @sorter.reversed then 'descending' else 'ascending'

		@treebox.beginUpdateBatch()
		try
			super rules, @sorter
		catch e
			log.error "Problem with filter/sort: " + e
			log.exception e
		finally
			@updateColumnSortUI @sortCol, direction
			@treebox.endUpdateBatch()

module.exports = TreeRoot
