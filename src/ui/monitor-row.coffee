{Cc, Ci, Cu} = require 'chrome'
log = require('ko/logging').getLogger 'preference-spy'

PrefData = require 'preferencespy/ui/pref-data'

class MonitorRow
	constructor: (@observer, @prefset, name) ->
		@time = new Date()

		# The observer represents a prefset, but the change
		# this row represents may have occurred in a sub-prefset.
		# Therefore, we have to create a new container and
		# reference it, rather than work through the observer.

		@container = PrefData.getContainer @prefset

		# Our visual name is the concatenation of the ancestor ids
		# with this preference name. The result is crude but
		# it's much more useful than a name like "1".
		nameArray = @container.buildNameArray name

		# HACK: if the scope is global, make sure "global" isn't
		# first. I think this has to do with "global" being a child
		# of "default".
		if @observer.scope is 'global'
			nameArray.shift() if nameArray[0] is 'global'

		@name = nameArray.join '\u21C0' # right-facing arrow

		@type = @container.getTypeForId name
		if @type is 'object'
			@value = '(container)'
		else
			@value = @container.getValueForId name, @type

		@scope = @observer.scope

module.exports = MonitorRow
