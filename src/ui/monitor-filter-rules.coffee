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

class SourceRule extends FilterRule
	constructor: (@source) ->
		@any = @source is 'any'

	accepts: (row) ->
		return true if @any
		row.getSourceHint() is @source

class FilterRules
	constructor: ->
		@rules = []

	load: ->
		@rules = []
		@rules.push @createNameRule()
		@rules.push @createValueRule()
		@rules.push @createTypeRule()
		@rules.push @createStateRule()
		#@rules.push @createSourceRule()

	createNameRule: ->
		text = document.getElementById('monitor-forname-text').value
		type = document.getElementById('monitor-forname-type').value

		if type is 'regex'
			new NameRegexRule text
		else
			new NamePlainRule text

	createValueRule: ->
		text = document.getElementById('monitor-forvalue-text').value
		type = document.getElementById('monitor-forvalue-type').value

		if type is 'regex'
			new ValueRegexRule text
		else
			new ValuePlainRule text

	createTypeRule: ->
		new TypeRule document.getElementById('monitor-fortype').value

	createStateRule: ->
		new StateRule document.getElementById('monitor-forstate').value

	createSourceRule: ->
		new SourceRule document.getElementById('monitor-forsource').value

	accepts: (row) ->
		#Do all rules accept this row?
		for rule in @rules
			return false unless rule.accepts row
		true

module.exports = FilterRules
