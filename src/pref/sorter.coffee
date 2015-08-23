#https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/nsITreeView)

log = require('ko/logging').getLogger 'preference-spy'


class Sorter
	reversed: false

	constructor: (@comparator) ->

	apply: (array) ->
		if @reversed
			comparator = @comparator
			array.sort (a, b) -> comparator b, a
		else
			array.sort @comparator

	reverse: ->
		@reversed = not @reversed

module.exports = Sorter
