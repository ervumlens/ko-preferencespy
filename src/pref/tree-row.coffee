
log = require('ko/logging').getLogger 'preference-spy'

#A TreeRow contains either a preference value
#or the root of a preference set
class TreeRow
	containerState: 'closed'
	depth: -1
	visible: true

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

		@nameToChild = {} unless @nameToChild
		@nameToChild[childRow.getName()] = childRow

		@children = [] unless @children
		@children.push childRow
		childRow.depth = @depth + 1

		if @lastChild
			@lastChild.nextSibling = childRow
			childRow.prevSibling = @lastChild

		@lastChild = childRow

	clearChildren: ->
		#Never clear @nameToChild. It only caches
		#the children and is not involved in UI decisions.

		for child in @children
			child.nextSibling = null
			child.prevSibling = null

		@lastChild = null
		@children = null

	load: ->
		@loader @name, @
		@valueString = @value.toString()
		@state = if @overwritten then 'overwritten' else 'inherited'
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

	getState: ->
		@load()
		@state

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
		return if @nameToChild or not @container

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
		@isContainer() and @containerState is 'open'

	open: ->
		return if @isOpen()

		@sort @root.sorter

		@containerState = 'open'
		@root.insertChildren @

	close: ->
		return unless @isOpen()

		@containerState = 'closed'
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

	filter: (rules) ->
		#Filtering works a bit like sort: We can't monkey
		#with the children unless we yank them all out and
		#then put them back in.

		#Get a list of all children, visible or otherwise.
		allChildren = []
		allChildren.push child for name, child of @nameToChild

		#Don't mess with filtering nested rows.
		@closeChildren()

		#Pulling in a new set of children
		@clearChildren()

		#We want to show only good children who follow the rules!
		for child in allChildren
			@addChild(child) if rules.accepts child

	filterAndSort: (rules, sorter) ->
		#The filter(rules) function can't sort because it
		#doesn't have a sorter! Call filterAndSort for most purposes.

		#Filtering works a bit like sort: We can't monkey
		#with the children unless we yank them all out and
		#then put them back in.

		#Get a list of all children, visible or otherwise.
		allChildren = []
		allChildren.push child for name, child of @nameToChild

		#Don't mess with filtering nested rows.
		@closeChildren()

		#Pulling in a new set of children.
		@clearChildren()

		goodChildren = []

		#We want to show only good children who follow the rules!
		for child in allChildren
			goodChildren.push child if rules.accepts child

		sorter.apply goodChildren

		for child in goodChildren
			@addChild child


module.exports = TreeRow
