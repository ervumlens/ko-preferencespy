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
	sourceView = new SourceView
	resultView = new ResultView
	monitorView = 0

@PreferenceSpyOnSourceSelected = ->
	log.warn "PreferenceSpyOnSourceSelected"
	prefset = sourceView.getPrefContainerFromSelection()
	if prefset
		document.getElementById('result-pref-id').value = prefset.id()
		resultView.load prefset

@PreferenceSpyOnUnload = ->
	log.warn "PreferenceSpyOnUnload"
	sourceView.dispose() if sourceView

@PreferenceSpyOnResize = ->
	#log.warn "PreferenceSpyOnResize"

@PreferenceSpyOnTabSelected = ->
	#log.warn "PreferenceSpyOnTabSelected"

@PreferenceSpy_DoSearch = ->
	resultView.doSearch()
