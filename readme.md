Goatee
=
Goatee is a ideological sibling of [Mustache Templates](http://mustache.github.com/). It shares the basic syntax of Mustache, but implements a few new awesome features which make templating much easier and removes some features which are unneccessary.

Purpose
-
1. Super simple templating syntax.
2. Ability to use the same template file/string in ANY language without modification. This fully separates business logic from formatting.
3. Eliminates numerous and needless data-type and data-existence checks which plague most templates. Normally when outputting data in a dynamic environment we often have to check for the existence of variables prior to usage, otherwise our system may throw a fatal error. In this system we no longer have to worry about any of that.

Difference From Mustache
-
1. Added positive conditionals, `{{:var}} content {{/var}}`. Mustache has a negative conditional, but no positive conditional.
2. Changed "invert" section (negative conditional) from `{{^notvar}} content {{/notvar}}` to `{{!notvar}} content {{/notvar}}`. The ! is more universally used as a NOT operator.
3. Added the ability to pass a "template" string and "data" struct to any simple variable. At process, it will use that template and data as the content which fills the simple variable. 

	This allows us to NEVER have to do pre-processing of content before sending it to the final template. This makes it much easier for our business logic to "piece" the templates together that it wants rather than having to know ahead of time and placing them as sub-templates.
	
4. Added the ability to pass a "template" string from server-side to client-side by "preserving" it. This way we aren't forced to clumsily include our templates to JS by putting them in external scripts.
5. Removed lambdas, one of the key functions of mustache is to be able to use the exact same template in any language. If we start adding the ability to add functions to our data objects we remove the ability to have language agnostic templates.
6. Removed data escaping. If you want to escape data, do it yourself. This will output exactly what you put in.
7. Removed partials. With the ability to have positive conditionals and pass-in templates, there is simply no reason to have sub-templates.

Basic Usage
-
1. Load the library for the language you will be using. Currently this GitHub has both Coldfusion and Javascript versions of the library.
2. Call the appropriate `fill(html, data)` and it will merge the data into the HTML of the template.

Syntax
-
Examples given using JS syntax, it is recommended to store your templates in variables, but for simplicity we passed them inline.

### Variable - {{var}}
Variables can be used in 2 ways.

1. If the the variable exists in the data object, and is a simple value (string, integer, boolean), it will be filled in with the value of it. If the variable does not exist, the tag is stripped.
2. If the the variable exists in the data object and is a structure with a "template" and "data" key, then it will fill the `{{var}}` with the product of that template and that data.
3. You can use {{%var}} to HTML escape a variable.

````
	template:
	<h1>{{title}}</h1>
	
	data:
	{ 
		title : "This is a test" 
	}
	
	result:
	<h1>This is a test</h1>
	
	template:
	<h1>{{title}}</h1>
	{{extra}}
	{{%escaped}}
	
	data:
	{
		title : "This is my title",
		extra : {
			template : "<h2>{{subtitle}}</h2>",
			data : {
				subtitle : "My subtitle"
			}
		},
		escaped : "<div>"
	}
	
	result:
	<h1>This is my title</h1>
	<h2>My subtitle</h2>
	&lt;div&gt;
````

The ability to pass a template and a data structure is key to making Goatee awesome. This way, we never have to pre-process any content before it reaches the final template. In addition, it allows a limitless amount of data/templates to be used in any context. In the mustache paradigm you must know AHEAD OF TIME, what templates may fill a specific spot.

### Positive Conditional (not in Mustache) - {{:var}} content {{/var}}
If the variable exists in the data object and is not false or empty string, the content in between the opening and closing of the tag will be processed, if not the tag (and everything in between is stripped).

````
	template: 
	{{:title}}<h1>{{title}}</h1>{{/title}}
	
	data:
	{ 
		title : "This is a test"
	}
	
	result:
	<h1>This is a test</h1>
	
	template: 
	{{:title}}<h1>{{title}}</h1>{{/title}}
	
	data:
	{ 
		othertitle : "This is a test"
	}
	
	result:
    empty string
````

### Negative Conditional - {{!var}} content {{/var}}
If the variable does not exist or it's value is false or empty string, then the content between the opening and closing tag will be processed. Otherwise it will be stripped.
	
Note: This feature differs from Mustache. Mustache uses "^" to handle a negative conditional or, as they call it, an "invert section". I found the "!" to be a far more universal NOT operator than "^".	

````
	template:
	{{!title}}<h1>I lack a title</h1>{{/title}}
	
	data:
	{
		overstuff : "stuff"
	}
	
	result:
	<h1>I lack a title</h1>
	
	template:
	{{!title}}<h1>I lack a title</h1>{{/title}}
	
	data:
	{
		title : "I have a title"
	}
	
	result:
	empty string
````
	
### Sections - {{#var}} content {{/var}}
There are 2 different ways that sections are processed.

1. If the var is an array, the content between the tags is iterated over, using the data of each item in the var to fill it in.
2. If the var is a structure/object, the content between the tags is filled in using the content of the var struct.

````
	template:
	{{#items}}
		<div class="item">
			<h1>{{title}}</h1>
			<h2>{{subtitle}}</h2>
		</div>
	{{/items}}
	
	data:
	{
		items : [
			{ title : "First", subtitle : "Sub First" },
			{ title : "Second", subtitle : "Sub Second" }
		]
	}
	
	result:
	<div class="item">
		<h1>First</h1>
		<h2>Sub First</h2>
	</div>
	<div class="item">
		<h1>Second</h1>
		<h2>Sub Second</h2>
	</div>
	
	template:
	{{#item}}
		<div class="item">
			<h1>{{title}}</h1>
			<h2>{{subtitle}}</h2>
		</div>
	{{/item}}
	
	data:
	{
		item : { 
			title : "First", 
			subtitle : "Second" 
		}
	}
	
	result:
	<div class="item">
		<h1>First</h1>
		<h2>Second</h2>
	</div>
	
	template:
	{{#item}}
		<div class="item">
			<h1>{{title}}</h1>
			<h2>{{subtitle}}</h2>
		</div>
	{{/item}}
	
	data:
	{
		item : {}
	}
	
	result:
	empty string
````

### Negative Section (not in Mustache) - {{-}} content {{/-}}
Negative sections allow you to access variables in the context above your current context. In example if your template has a section, while in the section, you can access variables in the scope above using a negative section.

````
	template:
	{{#items}}
		<div class="item {{-}}{{parentclass}}{{/-}}">
			<h1>{{title}}</h1>
			<h2>{{subtitle}}</h2>
		</div>
	{{/items}}
	
	data:
	{
		parentclass : "myClass",
		items : [
			{ title : "First", subtitle : "Sub First" },
			{ title : "Second", subtitle : "Sub Second" }
		]
	}
	
	result:
	<div class="item myClass">
		<h1>First</h1>
		<h2>Sub First</h2>
	</div>
	<div class="item myClass">
		<h1>Second</h1>
		<h2>Sub Second</h2>
	</div>
````

As you can see in the above example, the parentclass variable is not within the scope of an "item", but it is still accessible using a negative section {{-}}

Preserving Templates
-
Often your server-side language may determine either the template used or dynamically build the HTML string for a template which is passed on to javascript. In mustache, in order to pass a template to javascript it needs to be included via an external .js file. This allows us to get around that

````
	Example (in coldfusion):
	<script>
		var myTemplate = goatee.unpreserve(#SerializeJSON(goatee.preserve(templatestring))#);
	</script>
````

Now your javascript library can simply reference the variable `myTemplate` and use it whenever it needs to fill it with content. If you do not preserve the template, then if that block of HTML ever runs through a goatee call it will likely be processed out and stripped.