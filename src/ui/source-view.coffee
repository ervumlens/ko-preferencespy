{Cc, Ci, Cu} = require 'chrome'
{Services} = Cu.import 'resource://gre/modules/Services.jsm'

PrefData = require 'preferencespy/ui/pref-data'

log = require('ko/logging').getLogger 'preference-spy'

observerService = Cc["@mozilla.org/observer-service;1"].getService Ci.nsIObserverService
prefService = Cc["@activestate.com/koPrefService;1"].getService Ci.koIPrefService
partService = Cc["@activestate.com/koPartService;1"].getService Ci.koIPartService

#prefObserverService = prefService.prefs.prefObserverService;

SourceRow = require 'preferencespy/ui/source-row'
SourceRoot = require 'preferencespy/ui/source-root'
SourceActiveRoot = require 'preferencespy/ui/source-active-root'
SourceProjectsRoot = require 'preferencespy/ui/source-projects-root'
SourceFilesRoot = require 'preferencespy/ui/source-files-root'

class SourceView
	sorted: false
	selection: null
	loading: false
	disposed: false
	filterTerm: ''

	constructor: (@window, @resultView) ->
		#log.warn "SourceView::constructor"

		@.__defineGetter__ 'rowCount', =>
			@getRowCount()

		@activeSourcesRow = new SourceActiveRoot @, @window
		@allProjectsRow = new SourceProjectsRoot @
		@allFilesRow = new SourceFilesRoot @
		@roots = [
			@activeSourcesRow,
			@allProjectsRow,
			@allFilesRow,
		]

		@reindex()
		@tree = document.getElementById 'sources'
		@tree.view = @

		@offlineLoad()

	offlineLoad: ->
		@loading = true

		enqueue = (step) ->
			Services.tm.currentThread.dispatch step, Ci.nsIThread.DISPATCH_NORMAL

		progress = document.getElementById('source-progress')
		progress.setAttribute 'value', 0
		progress.removeAttribute 'hidden'

		roots = @roots.concat()
		root = roots.shift()

		step = =>
			return if @disposed
			if root
				if not root.hasMoreOfflineWork()
					root = roots.shift()
					enqueue step
				else
					percent = root.offlineStep()
					percent = 0 unless percent
					#log.warn "SourceView::stepProgress: #{percent}"
					progress.setAttribute 'value', percent
					enqueue step
			else
				# Done.
				progress.setAttribute 'hidden', 'true'
				@loading = false
				@update =>
					@reindex()
					@doSearch()

		enqueue step

	getCellText: (index, col) ->
		#log.warn "SourceView::getCellText #{index} #{col.id}"
		try
			root = @rootFor index
			switch col.id
				when 'sources-namecol' then root.getName(index)
				when 'sources-tagcol' then root.getTag(index)
				else '??'
		catch e
			log.exception e
			throw e

	getRowCount: ->
		#log.warn "SourceView::getRowCount -> #{@allFilesRow.lastIndex() + 1}"
		try
			#The number of rows is also the index of the last visible row plus 1.
			@allFilesRow.lastIndex() + 1
		catch e
			log.exception e
			throw e

	reindex: (removedIndices = null, updateUI = false) ->

		lastIndex = 0
		for root in @roots
			root.index = lastIndex
			#log.warn "SourceView::reindex: #{root.name} index is now #{root.index}"
			lastIndex = root.lastIndex() + 1

		# We're reindexing after removing
		if removedIndices and @selection.count and @selection.currentIndex in removedIndices
			@clearSelection()

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
		try
			@isRoot index
		catch e
			log.exception e
			throw e

	isContainerOpen: (index) ->
		#log.warn "SourceView::isContainerOpen #{index}"
		try
			@rootFor(index).isOpen()
		catch e
			log.exception e
			throw e

	isContainerEmpty: (index) ->
		#log.warn "SourceView::isContainerEmpty #{index}"
		try

			if @loading and index isnt 0 and @isRoot index
				# Hide the contents of everything but "Active"
				return true

			root = @rootFor index
			@rootFor(index).isEmpty()
		catch e
			log.exception e
			throw e

	isSeparator: (index) ->
		#log.warn "SourceView::isSeparator #{index}"
		false

	isSorted: ->
		#log.warn "SourceView::isSorted"
		@sorted

	getLevel: (index) ->
		#log.warn "SourceView::getLevel #{index}"
		try
			if @isRoot index
				0
			else
				1
		catch e
			log.exception e
			throw e

	hasNextSibling: (index, afterIndex) ->
		#log.warn "SourceView::hasNextSibling #{index}, #{afterIndex}"
		#row = @rowAt index
		#row.nextSibling?
		false #??

	getImgSrc: (index, col) ->
		null

	getRowProperties: (index) ->
		#log.warn "SourceView::getRowProperties #{index}"
		try
			if @isRoot index
				"root"
			else
				null
		catch e
			log.exception e
			throw e

	getCellProperties: (index, col) ->
		false

	getColumnProperties: (colId, col) ->
		false

	cycleHeader: (col) ->
		#log.warn "SourceView::cycleHeader #{col.id}"

	getParentIndex: (index) ->
		#log.warn "SourceView::getParentIndex #{index}"
		try
			root = @rootFor(index)
			if root.index is index
				-1
			else
				root.index
		catch e
			log.exception e
			throw e

	toggleOpenState: (index) ->
		#log.warn "SourceView::toggleOpenState #{index}"

		# No toggling until we're done loading
		return if @loading

		try
			return if @isContainerEmpty index
			root = @rootFor index
			if root.index isnt index
				throw new Error "Can only toggle root rows. Unexpected index #{index}"

			# Ensure our selection get sync'd up after opening/closing
			selectionIndex = @calcSelectionAfterToggleOpen root

			@update =>
				root.toggleOpen()
				@reindex()
				if selectionIndex < 0
					@clearSelection()
				else
					@setSelection selectionIndex
		catch e
			log.exception e
			throw e

	calcSelectionAfterToggleOpen: (root) ->
			return -1 unless @hasSelection()

			selectionIndex = @selection.currentIndex

			#log.warn "SourceView::calcSelectionAfterToggleOpen: selection = #{selectionIndex}"

			closing = root.isOpen()

			# Toggling the selection itself
			return selectionIndex if root.index is selectionIndex

			if closing and root.containsIndex(selectionIndex)
				# Our selection will be hidden. Bye, selection!
				#log.warn "SourceView::calcSelectionAfterToggleOpen: losing selection"
				-1
			else if root.index < selectionIndex
				# The selection will be shifted up or down. Determine the offset.
				if closing
					#log.warn "SourceView::calcSelectionAfterToggleOpen: moving selection down"
					selectionIndex - root.getChildCount()
				else
					#log.warn "SourceView::calcSelectionAfterToggleOpen: moving selection up"
					selectionIndex + root.getChildCount()
			else
				# No change.
				#log.warn "SourceView::calcSelectionAfterToggleOpen: no change"
				selectionIndex

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
		source = @getPrefSourceFromSelection()

		if source
			document.getElementById('result-pref-id').value = source.id
			@resultView.load source
		else
			document.getElementById('result-pref-id').value = ""
			@resultView.clear()

		@resultView.doSearch()

	clearSelection: ->
		@selection.clearSelection()

	setSelection: (index) ->
		@selection.select index

	getPrefSourceFromSelection: ->
		return unless @hasSelection()
		index = @getSelectionIndex()
		@rootFor(index).getPrefSource index

	hasSelection: ->
		@selection.count > 0

	getSelectionIndex: ->
		return -1 unless @hasSelection()
		@selection.currentIndex

	performAction: (action) ->
		log.warn "SourceView::performAction #{action}"

	performActionOnRow: (action, index) ->
		log.warn "SourceView::performActionOnRow #{action}, #{index}"

	performActionOnCell: (action, index, col) ->
		log.warn "SourceView::performActionOnCell #{action}, #{index}, #{col.id}"

	dispose: ->
		@roots.forEach (root) -> root.dispose()
		@disposed = true

	doSearch: ->
		# No searching while loading!
		return if @loading

		term = document.getElementById('sources-search').value

		if term is @filterTerm
			# Nothing to do here.
			return

		@filterTerm = term

		# Pass the search on to the roots
		# Note that a search may trigger loading pref data

		@update =>
			root.filter(term) for root in @roots
			@reindex()

		# There's no good way to track whether the underlying
		# row was removed. Better to clear the selection than
		# to let the UI parts get out of sync.

		@clearSelection()

module.exports = SourceView
