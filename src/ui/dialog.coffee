log = require('ko/logging').getLogger 'preference-spy'

SourceView = require 'preferencespy/ui/source-view'
ResultView = require 'preferencespy/ui/result-view'
MonitorView = require 'preferencespy/ui/monitor-view'

sourceView = null
resultView = null
monitorView = null

@PreferenceSpy_OnBlur = ->
	#log.warn "PreferenceSpyOnBlur"

@PreferenceSpy_OnFocus = ->
	#log.warn "PreferenceSpyOnFocus"

@PreferenceSpy_OnLoad = ->
	log.warn "PreferenceSpy_OnLoad"

	mainWindow = window.arguments[0].window

	try
		resultView = new ResultView mainWindow
		sourceView = new SourceView mainWindow, resultView
		monitorView = new MonitorView mainWindow
	catch e
		log.exception e

@PreferenceSpy_OnSourceSelected = ->
	log.warn "PreferenceSpy_OnSourceSelected"
	try
		sourceView.selectionChanged()
	catch e
		log.exception e

@PreferenceSpy_OnUnload = ->
	log.warn "PreferenceSpy_OnUnload"
	sourceView.dispose() if sourceView
	resultView.dispose() if resultView
	monitorView.dispose() if monitorView

@PreferenceSpy_OnResize = ->
	#log.warn "PreferenceSpyOnResize"

@PreferenceSpy_OnTabSelected = ->
	#log.warn "PreferenceSpyOnTabSelected"

@PreferenceSpy_DoResultSearch = ->
	resultView.doSearch()

@PreferenceSpy_DoSourcesSearch = ->
	sourceView.doSearch()

@PreferenceSpy_RefreshResults = ->
	resultView.refresh()

@PreferenceSpy_StartMonitoring = ->
	monitorView.startMonitoring()

@PreferenceSpy_StopMonitoring = ->
	monitorView.stopMonitoring()

@PreferenceSpy_DoMonitorFilter = ->
	monitorView.doFilter()

@PreferenceSpy_ChangeMonitorSettings = ->
	monitorView.refreshSettings()
