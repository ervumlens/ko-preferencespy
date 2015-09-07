ID_STOP			= 'monitor-settings-stop'
ID_START		= 'monitor-settings-start'
ID_GLOBAL		= 'monitor-settings-global'
ID_OPEN_PROJECT	= 'monitor-settings-openproject'
ID_OPEN_FILES	= 'monitor-settings-openfile'


class MonitorSettings
	monitorGlobal:		false
	monitorOpenProject:	false
	monitorOpenFiles:	false

	constructor: ->

	refresh: ->
		if @anyChecked(ID_GLOBAL, ID_OPEN_PROJECT, ID_OPEN_FILES)
			@enable ID_START
		else
			@disable ID_START

		@monitorGlobal = @checked ID_GLOBAL
		@monitorOpenProject = @checked ID_OPEN_PROJECT
		@monitorOpenFiles = @checked ID_OPEN_FILES

	start: ->
		@hide ID_START
		@show ID_STOP

		@disable ID_GLOBAL
		@disable ID_OPEN_PROJECT
		@disable ID_OPEN_FILES

	stop: ->
		@enable ID_GLOBAL
		@enable ID_OPEN_PROJECT
		@enable ID_OPEN_FILES

		@hide ID_STOP
		@show ID_START

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

module.exports = MonitorSettings
