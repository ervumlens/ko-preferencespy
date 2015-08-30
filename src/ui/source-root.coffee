{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'

class SourceRoot
	opened: false
	index: 0
	constructor: (@view, @name) ->
		@children = []
		@.__defineGetter__ 'childCount', =>
			@children.length

	load: ->

	childIndex: (index) ->
		index - @index - 1

	containsIndex: (index) ->
		return true if index is @index
		index > @index and @isOpen() and @childIndex(index) < @childCount

	addChild: (child) ->
		@children.push child

	getChild: (index) ->
		#log.warn "SourceRoot::getChild #{index}"
		child = @children[@childIndex(index)]
		if not child
			throw new Error "No child at index #{index} in root #{@name}(@index=#{@index})"
		child

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
		@opened = not @opened

	parentIndex: ->
		log.warn "SourceRoot::parentIndex"
		-1

	update: (fn) ->
		@view.update fn

	dispose: ->

module.exports = SourceRoot
