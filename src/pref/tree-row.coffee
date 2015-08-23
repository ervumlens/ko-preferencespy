
log = require('ko/logging').getLogger 'preference-spy'

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
			when 'preferencespy-valuecol' then @getValueString()
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

module.exports = TreeRow
