log = require('ko/logging').getLogger 'preference-spy'

class FilterRule
	accepts: (row) ->
		#Is the row acceptable to this rule?

class NameRegexRule extends FilterRule
	constructor: (text) ->
		@any = text.length is 0
		@regex = new RegExp(text) if not @any

	accepts: (row) ->
		return true if @any
		@regex.test row.getName()

class NamePlainRule extends FilterRule
	constructor: (@text) ->
		@any = @text.length is 0

	accepts: (row) ->
		return true if @any
		row.getName().indexOf(@text) isnt -1

class ValueRegexRule extends FilterRule
	constructor: (text) ->
		@any = text.length is 0
		@regex = new RegExp(text) if not @any

	accepts: (row) ->
		return true if @any
		@regex.test row.getValue()

class ValuePlainRule extends FilterRule
	constructor: (@text) ->
		@any = @text.length is 0

	accepts: (row) ->
		return true if @any
		row.getValueString().indexOf(@text) isnt -1

class TypeRule extends FilterRule
	constructor: (@type) ->
		@any = @type is 'any'

	accepts: (row) ->
		return true if @any
		row.getType() is @type

class StateRule extends FilterRule
	constructor: (@state) ->
		@any = @state is 'any'

	accepts: (row) ->
		return true if @any
		row.getState() is @state

class FilterRules
	constructor: ->
		@rules = []

	load: ->
		@rules = []
		@rules.push @createNameRule()
		@rules.push @createValueRule()
		@rules.push @createTypeRule()
		@rules.push @createStateRule()

	createNameRule: ->
		text = document.getElementById('search-forname-text').value
		type = document.getElementById('search-forname-type').value

		if type is 'regex'
			new NameRegexRule text
		else
			new NamePlainRule text

	createValueRule: ->
		text = document.getElementById('search-forvalue-text').value
		type = document.getElementById('search-forvalue-type').value

		if type is 'regex'
			new ValueRegexRule text
		else
			new ValuePlainRule text

	createTypeRule: ->
		new TypeRule document.getElementById('search-fortype').value

	createStateRule: ->
		new StateRule document.getElementById('search-forstate').value

	accepts: (row) ->
		#Do all rules accept this row?
		for rule in @rules
			return false unless rule.accepts row
		true

module.exports = FilterRules
