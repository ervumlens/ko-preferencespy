
log = require('ko/logging').getLogger 'preference-spy'

TreeRow = require 'preferencespy/pref/tree-row'

class TreeRoot extends TreeRow
	allRows: []

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

	getFilteredRow: (index) ->
		@allRows[index]

	getUnfilteredIndex: (index) ->
		index

	isOpen: ->
		true

	open: ->
	close: ->

	parentIndex: (index) ->
		@getFilteredRow(index).parentIndex()

	insertChildren: (row) ->
		#Insert the children into @allRows
		inserted = row.childCount()
		filteredIndex = row.index()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Inserting #{inserted} rows, starting at #{row.index()} (#{trueIndex})"

		newRows = row.children
		for i in [0 ... inserted]
			@allRows.splice trueIndex + 1 + i, 0, newRows[i]

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, inserted

	removeChildren: (row, filteredIndex) ->
		#remove the children into @allRows
		removed = row.childCount()
		filteredIndex = row.index()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Removing #{removed} rows, starting at #{row.index()} (#{trueIndex})"

		@allRows.splice trueIndex + 1, removed

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, -removed

	hasNextSibling: (index) ->
		row = @getFilteredRow index
		row.nextSibling?

	sort: (sorter, col) ->
		tree = document.getElementById 'preferencespy-tree'
		columns = col.columns

		if @sorter is sorter
			@sorter.reverse()
			direction = if @sorter.reversed then 'descending' else 'ascending'

			col.element.setAttribute 'sortDirection', direction
			tree.setAttribute 'sortDirection', direction
		else
			#Clear all sort attributes everywhere
			for i in [0 ... columns.length]
				otherCol = columns.getColumnAt(i)
				otherCol.element.removeAttribute 'sortDirection'

			col.element.setAttribute 'sortDirection', 'ascending'
			tree.setAttribute 'sortDirection', 'ascending'
			tree.setAttribute 'sortResource', col.id

			@sorter = sorter

		@treebox.beginUpdateBatch()
		try
			super
			@sorted = true
		catch e
			log.exception "Problem sorting: " + e
		finally
			@treebox.endUpdateBatch()

module.exports = TreeRoot
