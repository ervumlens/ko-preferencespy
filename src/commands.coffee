
{Cc, Ci, Cu} = require 'chrome'

log = require('ko/logging').getLogger 'preference-spy'
PrefLogger = require 'preferencespy/pref/pref-logger'
koAlert = require('ko/dialogs').alert

prefLogger = new PrefLogger

currentViewIsEditor = ->
	view = ko?.views?.manager?.currentView
	view && view.getAttribute('type') is 'editor'

anyOpenProjects = ->
	projects = ko?.projects?.manager?.getAllProjects?()
	projects && projects.length > 0

enableAllNodes = (cmdset) ->
	for child in cmdset.childNodes
		child.removeAttribute 'disabled'

disableAllNodes = (cmdset) ->
	for child in cmdset.childNodes
		child.setAttribute 'disabled', 'true'

( ->

	@updateProjectOnlyCommands = (cmdset) ->
		if anyOpenProjects()
			enableAllNodes cmdset
		else
			disableAllNodes cmdset

	@updateEditorViewOnlyCommands = (cmdset) ->
		if currentViewIsEditor()
			enableAllNodes cmdset
		else
			disableAllNodes cmdset

	@openGlobalPreferences = (window) ->
		ko.commands.doCommand('cmd_editPrefs');

	@openProjectPreferences = (window) ->
		return unless anyOpenProjects()

		window.openDialog(
			'chrome://komodo/content/pref/project.xul',
			'Komodo:ProjectPrefs',
			'chrome,dependent,resizable,close=yes,modal=yes');

	@openViewPreferences = (window) ->
		return unless currentViewIsEditor()

		view = ko?.views?.manager?.currentView


		_bundle = Cc['@mozilla.org/intl/stringbundle;1']
			  .getService(Ci.nsIStringBundleService)
			  .createBundle('chrome://komodo/locale/project/peFile.properties');
		args =
			title: _bundle.GetStringFromName 'filePreferences'
			view: view
			folder: false
			part: null

		window.openDialog(
			'chrome://komodo/content/pref/project.xul',
			'Komodo:ProjectPrefs',
			'chrome,dependent,resizable,close=yes,modal=yes',
			args);

	@toggleLogGlobalPreferenceChanges = ->
		prefLogger.toggleGlobal()

	@toggleLogProjectPreferenceChanges = (noAlert) ->
		prefLogger.toggleProjects()
		if prefLogger.loggingProjects and not noAlert
			props =
				title: 'Logging Project Preference Changes'

			koAlert 'Only changes to currently existing projects will be logged. \n\nCaution: Only saved preferences are logged. Transient changes and certain project preferences are not available.', props

	@toggleLogFilePreferenceChanges = (noAlert) ->
		prefLogger.toggleFiles()
		if prefLogger.loggingFiles and not noAlert
			props =
				title: 'Logging File Preference Changes'

			koAlert 'Only changes to currently existing files will be logged. \n\nCaution: Only saved preferences are logged. Transient changes are not available.', props

	@openNewDialog = (window) ->
		winOpts = 'centerscreen,chrome,resizable,scrollbars,dialog=no,close';
		window.openDialog 'chrome://preferencespy/content/main-dialog.xul', '_blank', winOpts, {window}


).call module.exports
