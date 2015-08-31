{Cc, Ci, Cu} = require 'chrome'
log = require('ko/logging').getLogger 'preference-spy'

class SourceRoot
	opened: false
	index: 0
	loaded: false
	filterTerm: ''
	disposed: false

	constructor: (@view, @name) ->
		@children = []
		@allChildren = [] # Ordered list of all available children

		@.__defineGetter__ 'childCount', =>
			@children.length

	load: ->
		return if @loaded
		@loaded = true

	offlineStep: ->
		100

	hasMoreOfflineWork: ->
		false

	childIndex: (index) ->
		index - @index - 1

	getChildCount: ->
		@children.length

	containsIndex: (index) ->
		return true if index is @index
		index > @index and @isOpen() and @childIndex(index) < @childCount

	addChild: (child) ->

		if @filterTerm.length is 0 or child.name.indexOf(@filterTerm) isnt -1
			@children.push child

		@allChildren.push child

	removeChildByIndex: (index) ->
		@children.splice index, 1

	filterChildren: ->
		@children = []

		if @filterTerm.length is 0
			for child in @allChildren
				@children.push child
		else
			for child in @allChildren
				@children.push(child) if child.name.indexOf(@filterTerm) isnt -1

	getChild: (index) ->
		#log.warn "SourceRoot::getChild #{index}"
		child = @children[@childIndex(index)]
		if not child
			throw new Error "No child at index #{index} in root #{@name}(@index=#{@index})"
		child

	getVisualProperties: (index) ->
		if index is @index
			'root'
		else
			@getChild(index).getVisualProperties()

	getPrefSource: (index) ->
		#roots have no prefs themselves
		return null if index is @index
		@getChild(index).source

	trimChildName: (name) ->
		return name if name.indexOf('http') is 0

		trimFrom = name.lastIndexOf '/'
		if trimFrom in [-1, name.length - 1]
			# Weird name, just ignore it
			name
		else
			name = name[trimFrom + 1 .. -1]

	getName: (index) ->
		#log.warn "SourceRoot::getName #{index}"
		if index is @index
			@name
		else
			@getChild(index).name

	getTag: (index) ->
		#log.warn "SourceRoot::getTag #{index}"
		if index is @index
			''
		else
			@getChild(index).tag

	getId: (index) ->
		if index is @index
			''
		else
			@getChild(index).id

	isEmpty: ->
		#log.warn "SourceRoot::isEmpty"
		@children.length is 0

	isOpen: ->
		#log.warn "SourceRoot::isOpen"
		@opened

	lastIndex: ->
		if @isOpen()
			@index + @children.length
		else
			@index

	toggleOpen: ->
		#log.warn "SourceRoot::toggleOpen"
		@load()
		opening = not @opened
		@opened = not @opened

		# Return the number of newly visible/removed children.

		if opening
			+@getChildCount()
		else
			-@getChildCount()

	parentIndex: ->
		log.warn "SourceRoot::parentIndex"
		-1

	update: (fn) ->
		@view.update fn

	filter: (term) ->
		@filterTerm = term
		@load()
		@filterChildren()

	dispose: ->
		@disposed = true

module.exports = SourceRoot
