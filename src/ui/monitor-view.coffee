
ID_STOP			= 'monitor-settings-stop'
ID_START		= 'monitor-settings-start'
ID_GLOBAL		= 'monitor-settings-global'
ID_OPEN_PROJECT	= 'monitor-settings-openproject'
ID_OPEN_FILES	= 'monitor-settings-openfile'

class MonitorView
	sorted: false
	rowCount: 0
	monitoring: false

	constructor: (@window) ->

	dispose: ->

	refreshSettings: ->
		return if @monitoring

		if @anyChecked(ID_GLOBAL, ID_OPEN_PROJECT, ID_OPEN_FILES)
			@enable ID_START
		else
			@disable ID_START

	startMonitoring: ->
		return if @monitoring

		@hide ID_START
		@show ID_STOP

		@disable ID_GLOBAL
		@disable ID_OPEN_PROJECT
		@disable ID_OPEN_FILES

		@connectGlobalObservers()
		@connectViewObservers()

		@monitoring = true


	stopMonitoring: ->
		return unless @monitoring

		@disconnectGlobalObservers()
		@disconnectViewObservers()

		@enable ID_GLOBAL
		@enable ID_OPEN_PROJECT
		@enable ID_OPEN_FILES

		@hide ID_STOP
		@show ID_START

		@monitoring = false

	doFilter: ->

	cycleHeader: (col) ->
		# TODO sort
		false

	getCellProperties: (row, col, arr) ->
		""

	getCellText: (row, col) ->
		"??"

	getCellValue: (row, col) ->
		"??"

	getColumnProperties: (col, arr) ->
		""

	getLevel: (index) ->
		0

	getParentIndex: (index) ->
		-1

	getRowProperties: (index, arr) ->
		""

	hasNextSibling: (index, afterIndex) ->
		false

	isContainer: (index) ->
		false

	isContainerEmpty: (index) ->
		true

	isContainerOpen: (index) ->
		false

	isEditable: (row, col) ->
		false

	isSelectable: (row, col) ->
		true

	isSeparator: (index) ->
		false

	isSorted: ->
		@sorted

	selectionChanged: ->

	setTree: (treebox) ->
		@treebox = treebox

	toggleOpenState: (index) ->
		0

	connectGlobalObservers: ->

	disconnectGlobalObservers: ->

	connectViewObservers: ->

	disconnectViewObservers: ->

	hide: (elementId) ->
		elt = document.getElementById elementId
		elt.setAttribute 'hidden', 'true'

	show: (elementId) ->
		elt = document.getElementById elementId
		elt.removeAttribute 'hidden'

	disable: (elementId) ->
		elt = document.getElementById elementId
		elt.setAttribute 'disabled', 'true'

	enable: (elementId) ->
		elt = document.getElementById elementId
		elt.removeAttribute 'disabled'

	anyChecked: (elementIds...) ->
		for elementId in elementIds
			return true if @checked elementId
		false

	checked: (elementId) ->
		elt = document.getElementById elementId
		elt.hasAttribute 'checked'

module.exports = MonitorView
