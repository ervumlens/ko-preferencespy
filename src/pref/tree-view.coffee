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

	clearChildren: ->
		for child in @children
			child.nextSibling = null
			child.prevSibling = null

		@lastChild = null
		@children = null

	load: ->
		@loader @name, @
		@valueString = @value.toString()
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

	getValueString: ->
		@load()
		@valueString

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
		@isContainer() and @state is 'open'

	open: ->
		return if @isOpen()

		@sort @root.sorter

		@state = 'open'
		@root.insertChildren @

	close: ->
		return unless @isOpen()

		@state = 'closed'
		# Close all children first. This ensures
		# our numbers add up.
		@closeChildren()

		@root.removeChildren @

	closeChildren: ->
		return unless @isOpen()
		child.close() for child in @children

	sort: (sorter) ->
		return unless @isOpen()

		#Don't mess with sorting nested rows.
		#Just close everyone up.
		@closeChildren()

		# Children are stored in @children, but also
		# linked to one another. To sort, we have
		# to clear both our state and the child links.

		children = @children
		@clearChildren()

		sorter.apply children

		for child in children
			@addChild child

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


class Sorter
	reversed: false

	constructor: (@comparator) ->

	apply: (array) ->
		if @reversed
			comparator = @comparator
			array.sort (a, b) -> comparator b, a
		else
			array.sort @comparator

	reverse: ->
		@reversed = not @reversed

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
