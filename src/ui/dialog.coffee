log = require('ko/logging').getLogger 'preference-spy'

SourceView = require 'preferencespy/ui/source-view'
ResultView = require 'preferencespy/ui/result-view'
#MonitorView = require 'preferencespy/ui/monitor-view'

sourceView = null
resultView = null
monitorView = null

@PreferenceSpyOnBlur = ->
	#log.warn "PreferenceSpyOnBlur"

@PreferenceSpyOnFocus = ->
	#log.warn "PreferenceSpyOnFocus"

@PreferenceSpyOnLoad = ->
	log.warn "PreferenceSpyOnLoad"

	mainWindow = window.arguments[0].window
	#log.warn "PreferenceSpyOnLoad::arguments contains window? #{sourceWindow}"

	resultView = new ResultView mainWindow
	sourceView = new SourceView mainWindow, resultView
	monitorView = 0


@PreferenceSpyOnSourceSelected = ->
	log.warn "PreferenceSpyOnSourceSelected"
	sourceView.selectionChanged()

@PreferenceSpyOnUnload = ->
	log.warn "PreferenceSpyOnUnload"
	sourceView.dispose() if sourceView
	resultView.dispose() if resultView

@PreferenceSpyOnResize = ->
	#log.warn "PreferenceSpyOnResize"

@PreferenceSpyOnTabSelected = ->
	#log.warn "PreferenceSpyOnTabSelected"

@PreferenceSpy_DoSearch = ->
	resultView.doSearch()
