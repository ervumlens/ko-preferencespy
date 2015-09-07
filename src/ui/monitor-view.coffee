{Cc, Ci, Cu} = require 'chrome'
log = require('ko/logging').getLogger 'preference-spy'

COL_TIME	= "changed-timecol"
COL_SCOPE	= "changed-scopecol"
COL_NAME	= "changed-namecol"
COL_VALUE	= "changed-valuecol"
COL_TYPE	= "changed-typecol"


observerService = Cc["@mozilla.org/observer-service;1"].getService(Ci.nsIObserverService)
prefService = Cc["@activestate.com/koPrefService;1"].getService(Ci.koIPrefService)
partService = Cc["@activestate.com/koPartService;1"].getService(Ci.koIPartService)

MonitorSettings = require 'preferencespy/ui/monitor-settings'
MonitorRow = require 'preferencespy/ui/monitor-row'

PrefData = require 'preferencespy/ui/pref-data'

class MonitorView
	sorted: false
	monitoring: false

	constructor: (@window) ->
		@prefObservers = []
		@rows = []
		@allRows = []

		@settings = new MonitorSettings()
		@.__defineGetter__ 'rowCount', =>
			@rows.length

		@tree = document.getElementById 'changed'
		@tree.view = @

	dispose: ->
		@stopMonitoring()

	refreshSettings: ->
		return if @monitoring

		@settings.refresh()

	startMonitoring: ->
		return if @monitoring

		@settings.start()

		@connectGlobalObservers()
		@connectMonitorObservers()

		@monitoring = true


	stopMonitoring: ->
		return unless @monitoring

		@disconnectGlobalObservers()
		@disconnectMonitorObservers()

		@settings.stop()

		@monitoring = false

	preferenceChanged: (observer, prefset, name, data) ->
		#log.warn "MonitorView::preferenceChanged: #{observer.scope}, #{name}"
		@addRow observer, prefset, name

	addRow: (observer, prefset, name) ->
		@allRows.push new MonitorRow observer, prefset, name
		@doFilterAndSort()

	doFilter: ->

	doFilterAndSort: ->
		@update =>
			@rows = @allRows.concat()

	update: (fn) ->
		@treebox.beginUpdateBatch()
		try
			fn()
		catch e
			log.exception e

		@treebox.endUpdateBatch()

	cycleHeader: (col) ->
		# TODO sort
		false

	getCellProperties: (index, col, arr) ->
		""

	getCellText: (index, col) ->
		row = @rows[index]
		switch col.id
			when COL_TIME then row.time
			when COL_NAME then row.name
			when COL_VALUE then row.value
			when COL_TYPE then row.type
			when COL_SCOPE then row.scope
			else "??"

	getCellValue: (index, col) ->
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

	isEditable: (index, col) ->
		false

	isSelectable: (index, col) ->
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
		# listen for view_opened & view_closed on the window
		# listen for current_project_changed on the observer service

	disconnectGlobalObservers: ->

	connectMonitorObservers: ->

		if @settings.monitorGlobal
			@prefObservers.push new GlobalPreferenceObserver @

		for observer in @prefObservers
			observer.connect()

	disconnectMonitorObservers: ->
		for observer in @prefObservers
			observer.disconnect()

		@prefObservers.splice(0)

class PreferenceObserver
	connected: false
	scope: 'unknown'

	constructor: (@view) ->

	observe: (prefset, name, data) ->
		try
			@view.preferenceChanged @, prefset, name, data
		catch e
			log.exception e

	connect: ->
		return if @connected

		@container.addObserver @
		@connected = true

	disconnect: ->
		return unless @connected

		@container.removeObserver @

	dispose: ->
		@disconnect()

class GlobalPreferenceObserver extends PreferenceObserver
	scope: 'global'

	constructor: ->
		super
		@prefset = prefService.getPrefs 'global'
		@container = PrefData.getContainer @prefset

module.exports = MonitorView
