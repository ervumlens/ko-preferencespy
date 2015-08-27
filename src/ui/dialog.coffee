log = require('ko/logging').getLogger 'preference-spy'

SourceView = require 'preferencespy/ui/source-view'
#ResultView = require 'preferencespy/ui/result-view'
#MonitorView = require 'preferencespy/ui/monitor-view'

@PreferenceSpyOnBlur = ->
	log.warn "PreferenceSpyOnBlur"

@PreferenceSpyOnFocus = ->
	log.warn "PreferenceSpyOnFocus"

@PreferenceSpyOnLoad = ->
	log.warn "PreferenceSpyOnLoad"
	sourceView = new SourceView
	resultView = 0
	monitorView = 0

@PreferenceSpyOnUnload = ->
	log.warn "PreferenceSpyOnUnload"

@PreferenceSpyOnResize = ->
	log.warn "PreferenceSpyOnResize"

@PreferenceSpyOnTabSelected = ->
	log.warn "PreferenceSpyOnTabSelected"
