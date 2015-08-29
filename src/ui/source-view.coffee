{Cc, Ci, Cu} = require 'chrome'

PrefData = require 'preferencespy/ui/pref-data'

log = require('ko/logging').getLogger 'preference-spy'


observerService = Cc["@mozilla.org/observer-service;1"].getService Ci.nsIObserverService
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService
partService = Cc["@activestate.com/koPartService;1"].getService Ci.koIPartService

#prefObserverService = prefService.prefs.prefObserverService;

SourceRow = require 'preferencespy/ui/source-row'
SourceRoot = require 'preferencespy/ui/source-root'
SourceActiveRoot = require 'preferencespy/ui/source-active-root'

class SourceView
	sorted: false
	selection: null

	constructor: (@window, @resultView) ->
		#log.warn "SourceView::constructor"

		@.__defineGetter__ 'rowCount', =>
			@getRowCount()

		@activeSourcesRow = new SourceActiveRoot @, @window
		@allProjectsRow = new SourceRoot @, 'All Projects'
		@allFilesRow = new SourceRoot @, 'All Files'
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

	reindex: (removedIndices = null, updateUI = false) ->

		lastIndex = 0
		for root in @roots
			root.index = lastIndex
			log.warn "SourceView::reindex: #{root.name} index is now #{root.index}"
			lastIndex = root.lastIndex() + 1

		# We're reindexing after removing
		if removedIndices and @selection.count and @selection.currentIndex in removedIndices
			@selection.clearSelection()

		if updateUI
			@treebox.invalidate()

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

	update: (fn) ->
		if @treebox
			@treebox.beginUpdateBatch()
			try
				fn()
				@reindex()
			finally
				@treebox.endUpdateBatch()
		else
			fn()

	isSelectable: (index, col) ->
		#log.warn "SourceView::isSelectable #{index}, #{col.id}"
		true

	selectionChanged: ->
		prefset = @getPrefContainerFromSelection()

		if prefset
			document.getElementById('result-pref-id').value = prefset.id()
			@resultView.load prefset, false
		else
			document.getElementById('result-pref-id').value = ""
			@resultView.clear false

		@resultView.doSearch()

	getPrefContainerFromSelection: ->
		return unless @selection.count is 1
		index = @selection.currentIndex
		@rootFor(index).getPrefContainer index


	performAction: (action) ->
		log.warn "SourceView::performAction #{action}"

	performActionOnRow: (action, index) ->
		log.warn "SourceView::performActionOnRow #{action}, #{index}"

	performActionOnCell: (action, index, col) ->
		log.warn "SourceView::performActionOnCell #{action}, #{index}, #{col.id}"

	dispose: ->
		@roots.forEach (root) -> root.dispose()

module.exports = SourceView
