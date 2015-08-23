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
		@parent.addChild @

	index: ->
		if @prevSibling
			@prevSibling.lastIndex() + 1
		else
			@parentIndex() + 1

	lastIndex: ->
		if @isOpen() and @lastChild
			@lastChild.lastIndex()
		else
			@index()

	parentIndex: ->
		@parent.index()

	addChild: (childRow) ->
		childRow.root = @root
		@children = [] unless @children
		@children.push childRow
		childRow.depth = @depth + 1

		if @lastChild
			@lastChild.nextSibling = childRow
			childRow.prevSibling = @lastChild

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

	loadChildren: ->
		@load()
		#log.warn "Populating #{@name}? it has #{@children?.length} children and #{@container?} container"
		return if @children or not @container

		@container.visitNames (name, loader) =>
			#log.warn "Added #{name}"
			row = new TreeRow name, @, loader


	toggleOpen: ->
		@loadChildren()
		if @isOpen()
			@close()
		else
			@open()

	isOpen: ->
		return false unless @isContainer()
		@state is 'open'

	open: ->
		return if @isOpen()

		@state = 'open'
		@root.insertChildren @

	close: ->
		return unless @isOpen()

		@state = 'closed'
		#Close all children first. This ensures
		#our numbers add up.
		child.close() for child in @children

		@root.removeChildren @


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

	visibleRowCount: ->
		@allRows.length

	getFilteredRow: (index) ->
		@allRows[index]

	getUnfilteredIndex: (index) ->
		index

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

		#Update @filteredRowsToAllRows
		#TODO re-sort, filter to get this right

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, inserted

	removeChildren: (row, filteredIndex) ->
		#remove the children into @allRows
		removed = row.childCount()
		filteredIndex = row.index()
		trueIndex = @getUnfilteredIndex filteredIndex
		#log.warn "Removing #{removed} rows, starting at #{row.index()} (#{trueIndex})"

		@allRows.splice trueIndex + 1, removed

		#Update @filteredRowsToAllRows
		#TODO re-sort, filter to get this right

		#Call @treebox.rowCountChanged
		@treebox.rowCountChanged filteredIndex + 1, -removed

#A TreeView implements nsITreeView
class TreeView
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
		false

	getLevel: (index) ->
		row = @getFilteredRow index
		row.depth

	hasNextSibling: (index, afterIndex) ->
		row = @getFilteredRow index
		row.next?

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
			when 'preferencespy-namecol' then @sortByName()
			when 'preferencespy-valuecol' then @sortByValue()
			when 'preferencespy-typecol' then @sortByType()
			when 'preferencespy-overwrittencol' then @sortByOverwritten()

	sortByName: ->

	sortByValue: ->

	sortByType: ->

	sortByOverwritten: ->

	getParentIndex: (index) ->
		@root.parentIndex index

	toggleOpenState: (index) ->
		return if @isContainerEmpty index
		row = @getFilteredRow index
		row.toggleOpen()
		@treebox.invalidateRow index

module.exports = TreeView
