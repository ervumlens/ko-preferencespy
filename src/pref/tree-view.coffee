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
	constructor: (@name, @loader) ->

	load: ->
		values = @loader @name, @
		@load = ->

	getText: (col) ->
		switch col.id
			when 'preferencespy-namecol' then @getName()
			when 'preferencespy-valuecol' then @getValue()
			when 'preferencespy-typecol' then @getType()
			when 'preferencespy-overwrittencol' then @getOverwritten()

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

#A TreeView implements nsITreeView
module.exports = class TreeView
	#All new rows go in here.
	allRows: []
	filteredRowsToAllRows: []
	rowCount: 0

	constructor: (prefData) ->
		prefData.visitNames (name, loader) => @addRow name, loader

	addRow: (name, loader) ->
		newRow = new TreeRow name, loader
		@allRows.push newRow
		@filteredRowsToAllRows.push @rowCount
		@rowCount++

	getFilteredRow: (index) ->
		@allRows[@filteredRowsToAllRows[index]]

	getCellText: (index, col) ->
		#log.warn "value: #{index}, #{col.id}"
		row = @getFilteredRow index
		row.getText col

	getCellValue: (index, col) ->
		'value'

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
		true

	isSeparator: (index) ->
		false

	isSorted: ->
		false

	getLevel: (index) ->
		0

	hasNextSibling: (index, afterIndex) ->
		false

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
