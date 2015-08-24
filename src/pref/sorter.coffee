#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'


class Sorter
	reversed: false
	direction: 'ascending'

	constructor: (@id, @comparator) ->

	apply: (array) ->
		if @reversed
			comparator = @comparator
			array.sort (a, b) -> comparator b, a
		else
			array.sort @comparator

	reverse: ->
		@reversed = not @reversed
		@direction = if @reversed then 'descending' else 'ascending'

	clone: ->
		new Sorter @id, @comparator


module.exports = Sorter
