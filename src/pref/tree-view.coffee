#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'

TreeRow 	= require 'preferencespy/pref/tree-row'
TreeRoot	= require 'preferencespy/pref/tree-root'
Sorter		= require 'preferencespy/pref/sorter'

#A TreeView implements nsITreeView
class TreeView
	sorted: false
	nameSorter: 	new Sorter (row0, row1) -> row0.getName() > row1.getName()
	valueSorter: 	new Sorter (row0, row1) -> row0.getValueString() > row1.getValueString()
	typeSorter: 	new Sorter (row0, row1) -> row0.getType() > row1.getType()
	overwrittenSorter: new Sorter (row0, row1) -> row0.getOverwritten() > row1.getOverwritten()

	constructor: (prefData) ->
		#Root is a virtual row under which all top-level rows belong.
		@root = new TreeRoot
		prefData.visitNames (name, loader) =>
			new TreeRow name, @root, loader

		@.__defineGetter__ 'rowCount', ->
			@root.visibleRowCount()

	getFilteredRow: (index) ->
		@root.getFilteredRow index

	getUnfilteredIndex: (index) ->
		@root.getUnfilteredIndex index

	getCellText: (index, col) ->
		#log.warn "value: #{index}, #{col.id}"
		row = @getFilteredRow index
		row.getText col

	getCellValue: (index, col) ->
		null

	setTree: (treebox) ->
		@treebox = treebox
		@root.treebox = treebox

	isEditable: (index, col) ->
		col.editable

	isContainer: (index) ->
		row = @getFilteredRow index
		row.isContainer()

	isContainerOpen: (index) ->
		row = @getFilteredRow index
		row.isOpen()

	isContainerEmpty: (index) ->
		row = @getFilteredRow index
		row.isContainerEmpty()

	isSeparator: (index) ->
		false

	isSorted: ->
		@sorted

	getLevel: (index) ->
		row = @getFilteredRow index
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
		log.warn "cycleHeader: #{col.id}"
		switch col.id
			when 'preferencespy-namecol' then @sortByName(col)
			when 'preferencespy-valuecol' then @sortByValue(col)
			when 'preferencespy-typecol' then @sortByType(col)
			when 'preferencespy-overwrittencol' then @sortByOverwritten(col)


	doSort: (sorter, col) ->
		@root.sort sorter, col

	sortByName: (col) ->
		@doSort @nameSorter, col

	sortByValue: (col) ->
		@doSort @valueSorter, col

	sortByType: (col) ->
		@doSort @typeSorter, col

	sortByOverwritten: (col) ->
		@doSort @overwrittenSorter, col

	getParentIndex: (index) ->
		@root.parentIndex index

	toggleOpenState: (index) ->
		return if @isContainerEmpty index
		row = @getFilteredRow index
		row.toggleOpen()
		@treebox.invalidateRow index

module.exports = TreeView
