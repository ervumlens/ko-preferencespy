
log = require('ko/logging').getLogger 'preference-spy'

ResultRow = require 'preferencespy/ui/result-row'
Sorter = require 'preferencespy/ui/sorter'

class ResultRoot extends ResultRow
	allRows: []

	constructor: ->
		@root = @
		@isRoot = true

	index: ->
		-1

	addChild: (childRow) ->
		super
		@allRows.push childRow

	dispose: ->
		super
		@treebox = null

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

module.exports = ResultRoot
