#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'

ColumnIds =
	'preferencespy-namecol': 0
	'preferencespy-valuecol': 1
	'preferencespy-typecol': 2
	'preferencespy-overwrittencol': 3

#A TreeRow contains either a preference value
#or the root of a preference set
class TreeRow
	state: 'closed'
	depth: -1

	constructor: (@name, @parent, @loader) ->
		@parent.addChild(@) if @parent

	addChild: (childRow) ->
		@children = [] unless @children
		@children.push childRow
		childRow.depth = @depth + 1
		@lastChild.next = childRow if @lastChild
		@lastChild = childRow

	load: ->
		values = @loader @name, @
		@load = ->

	getText: (col) ->
		switch col.id
			when 'preferencespy-namecol' then @getName()
			when 'preferencespy-valuecol' then @getValue()
			when 'preferencespy-typecol' then @getType()
			when 'preferencespy-overwrittencol'
				if @getOverwritten()
					'✓'
				else
					''

	getName: ->
		@name

	getValue: ->
		@load()
		@value

	getType: ->
		@load()
		@type

	getOverwritten: ->
		@load()
		@overwritten

	isContainer: ->
		@load()
		@container?

	isContainerEmpty: ->
		@load()
		if @container then @container.isEmpty() else true

	childCount: ->
		@children?.length or 0

	populate: ->
		@load()
		#log.warn "Populating #{@name}? it has #{@children?.length} children and #{@container?} container"
		return if @children or not @container

		@container.visitNames (name, loader) =>
			log.warn "Added #{name}"
			row = new TreeRow name, @, loader

	isOpen: ->
		@state is 'open'

	open: ->
		@state = 'open'

	close: ->
		@state = 'closed'


#A TreeView implements nsITreeView
class TreeView

	#All new rows go in here.
	allRows: []

	#Map visual rows to data rows
	#filteredRowsToAllRows: []

	#Number of displayed rows
	rowCount: 0

	constructor: (prefData) ->
		#Root is a virtual row under which all top-level rows belong.
		@root = new TreeRow
		prefData.visitNames (name, loader) => @addRow name, @root, loader

	addRow: (name, parent, loader) ->
		newRow = new TreeRow name, parent, loader
		@allRows.push newRow
		@root.children.push newRow
		#@filteredRowsToAllRows.push @rowCount
		@rowCount++

	getFilteredRow: (index) ->
		#@allRows[@filteredRowsToAllRows[index]]
		@allRows[index]

	getUnfilteredIndex: (index) ->
		index

	getCellText: (index, col) ->
		#log.warn "value: #{index}, #{col.id}"
		row = @getFilteredRow index
		row.getText col

	getCellValue: (index, col) ->
		null

	setTree: (treebox) ->
		@treebox = treebox

	isEditable: (index, col) ->
		col.editable

	isContainer: (index) ->
		row = @getFilteredRow index
		row.isContainer()

	isContainerOpen: (index) ->
		false

	isContainerEmpty: (index) ->
		row = @getFilteredRow index
		row.isContainerEmpty()

	isSeparator: (index) ->
		false

	isSorted: ->
		false

	getLevel: (index) ->
		row = @getFilteredRow index
		row.depth

	hasNextSibling: (index, afterIndex) ->
		row = @getFilteredRow index
		row.next?

	getImgSrc: (index, col) ->
		null

	getRowProperties: (index, props) ->
		false

	getCellProperties: (index, col, props) ->
		false

	getColumnProperties: (colId, col, props) ->
		false

	cycleHeader: (col, element) ->
		false

	toggleOpenState: (index) ->
		return if @isContainerEmpty index
		row = @getFilteredRow index
		row.populate()

		if row.isOpen()
			row.close()
			@removeChildren row, index
		else
			row.open()
			@insertChildren row, index

	insertChildren: (row, filteredIndex) ->
		#Insert the children into @allRows
		inserted = row.childCount()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Inserting #{inserted} rows, starting at #{filteredIndex} (#{trueIndex})"

		newRows = row.children
		for i in [0 ... inserted]
			@allRows.splice trueIndex + 1 + i, 0, newRows[i]

		#Update @rowCount
		@rowCount += inserted

		#Update @filteredRowsToAllRows
		#TODO re-sort, filter to get this right

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, inserted

	removeChildren: (row, filteredIndex) ->
		#remove the children into @allRows
		removed = row.childCount()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Removing #{removed} rows, starting at #{filteredIndex} (#{trueIndex})"

		@allRows.splice trueIndex + 1, removed

		#Update @rowCount
		@rowCount -= removed

		#Update @filteredRowsToAllRows
		#TODO re-sort, filter to get this right

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, -removed


module.exports = TreeView
