#CommonView = require 'preferencespy/ui/common-view'

PrefData = require 'preferencespy/ui/pref-data'

log = require('ko/logging').getLogger 'preference-spy'

{Cc, Ci, Cu} = require 'chrome'

observerService = Cc["@mozilla.org/observer-service;1"].getService Ci.nsIObserverService
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService
#prefObserverService = prefService.prefs.prefObserverService;

class SourceRow
	constructor: (@parent, @name, @prefRootKey, @prefKey = null) ->
	load: ->
		#lazy load the pref container
		rootPrefs = prefService.getPrefs @prefRootKey
		if @prefKey
			@container = PrefData.getContainer rootPrefs.getPref @prefKey
		else
			@container = PrefData.getContainer rootPrefs
		@load = ->
	getPrefContainer: ->
		@load()
		@container

class SourceRoot
	opened: false
	index: 0
	constructor: (@name) ->
		@children = []
		@.__defineGetter__ 'childCount', =>
			@children.length

	childIndex: (index) ->
		index - @index - 1

	containsIndex: (index) ->
		return true if index is @index
		index > @index and @isOpen() and @childIndex(index) < @childCount

	getChild: (index) ->
		#log.warn "SourceRoot::getChild #{index}"
		child = @children[@childIndex(index)]
		if not child
			throw new Error "No child at index #{index} in root #{@name}(@index=#{@index})"
		child

	getPrefContainer: (index) ->
		#roots have no prefs themselves
		return null if index is @index
		@getChild(index).getPrefContainer()

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
		@opened = not @opened

	parentIndex: ->
		log.warn "SourceRoot::parentIndex"
		-1

	dispose: ->

class SourceActiveRoot extends SourceRoot
	constructor: ->
		super 'Active'
		@children.push new SourceRow @, 'global', 'global'
		#TODO add global and anything open
		@resetCurrentProjects()
		@resetCurrentFiles()
		@resetCurrentEditors()
		observerService.addObserver @, 'current_project_changed', false

	resetCurrentProjects: ->

	resetCurrentFiles: ->

	resetCurrentEditors: ->

	observe: (subject, topic, data) ->
		log.warn "SourceActiveRoot::observe #{topic}"
		switch topic
			when 'current_project_changed' then @resetCurrentProjects()


	dispose: ->
		try
			observerService.removeObserver @, 'current_project_changed'
		catch

class SourceView
	sorted: false
	selection: null

	constructor: ->
		#log.warn "SourceView::constructor"

		@.__defineGetter__ 'rowCount', =>
			@getRowCount()

		@activeSourcesRow = new SourceActiveRoot
		@allProjectsRow = new SourceRoot('All Projects')
		@allFilesRow = new SourceRoot('All Files')
		@roots = [@activeSourcesRow, @allProjectsRow, @allFilesRow]
		@reindex()
		@tree = document.getElementById 'sources'
		@tree.view = @

	getCellText: (index, col) ->
		#log.warn "SourceView::getCellText #{index} #{col.id}"
		root = @rootFor index
		switch col.id
			when 'sources-namecol' then root.getName(index)
			when 'sources-tagcol' then root.getTag(index)
			else '??'

	getRowCount: ->
		log.warn "SourceView::getRowCount -> #{@allFilesRow.lastIndex() + 1}"
		#The number of rows is also the index of the last visible row plus 1.
		@allFilesRow.lastIndex() + 1

	reindex: ->
		lastIndex = 0
		for root in @roots
			root.index = lastIndex
			log.warn "SourceView::reindex: #{root.name} index is now #{root.index}"
			lastIndex = root.lastIndex() + 1

	rootFor: (index) ->
		for root in @roots
			return root if root.containsIndex index

		throw new Error "No root for index #{index}"

	isRoot: (index) ->
		for root in @roots
			return true if root.index is index
		false

	getCellValue: (index, col) ->
		#log.warn "SourceView::getCellValue #{index} #{col.id}"
		null

	setTree: (treebox) ->
		@treebox = treebox

	isEditable: (index, col) ->
		#log.warn "SourceView::isEditable #{index} #{col.id}"
		col.editable

	isContainer: (index) ->
		#log.warn "SourceView::isContainer #{index}"
		@isRoot index

	isContainerOpen: (index) ->
		#log.warn "SourceView::isContainerOpen #{index}"
		@rootFor(index).isOpen()

	isContainerEmpty: (index) ->
		#log.warn "SourceView::isContainerEmpty #{index}"
		root = @rootFor index
		@rootFor(index).isEmpty()

	isSeparator: (index) ->
		#log.warn "SourceView::isSeparator #{index}"
		false

	isSorted: ->
		#log.warn "SourceView::isSorted"
		@sorted

	getLevel: (index) ->
		#log.warn "SourceView::getLevel #{index}"
		if @isRoot index
			0
		else
			1

	hasNextSibling: (index, afterIndex) ->
		log.warn "SourceView::hasNextSibling #{index}, #{afterIndex}"
		#row = @rowAt index
		#row.nextSibling?
		false #??

	getImgSrc: (index, col) ->
		null

	getRowProperties: (index) ->
		#log.warn "SourceView::getRowProperties #{index}"
		if @isRoot index
			"root"
		else
			null

	getCellProperties: (index, col) ->
		false

	getColumnProperties: (colId, col) ->
		false

	cycleHeader: (col) ->
		#log.warn "SourceView::cycleHeader #{col.id}"

	getParentIndex: (index) ->
		#log.warn "SourceView::getParentIndex #{index}"

		root = @rootFor(index)
		if root.index is index
			-1
		else
			root.index

	toggleOpenState: (index) ->
		log.warn "SourceView::toggleOpenState #{index}"
		return if @isContainerEmpty index
		root = @rootFor index

		@update =>
			root.toggleOpen()
			@reindex()

	doSearch: ->

	update: (fn) ->
		if @treebox
			@treebox.beginUpdateBatch()
			try
				fn()
			finally
				@treebox.endUpdateBatch()
		else
			fn()

	isSelectable: (index, col) ->
		#log.warn "SourceView::isSelectable #{index}, #{col.id}"
		true

	getPrefContainerFromSelection: ->
		return unless @selection.count is 1
		index = @selection.currentIndex
		@rootFor(index).getPrefContainer index


	performAction: (action) ->
		#log.warn "SourceView::performAction #{action}"

	performActionOnRow: (action, index) ->
		#log.warn "SourceView::performActionOnRow #{action}, #{index}"

	performActionOnCell: (action, index, col) ->
		#log.warn "SourceView::performActionOnCell #{action}, #{index}, #{col.id}"

	dispose: ->
		@roots.forEach (root) -> root.dispose()

module.exports = SourceView
