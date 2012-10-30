<!--- This is the templating engine derived from Mustache. It is usable anywhere, in any context, all it does is merge data into HTML --->
<cfcomponent>
	<cffunction name="init">
		<cfset variables.tagRegex = CreateObject("java", "java.util.regex.Pattern").compile("\{\{([##!:%\/-]?)(.*?)\}\}", 32)>

		<cfreturn this>
	</cffunction>
	
	<!--- Templating entry point function, this functions merges a mustache template with it's data --->
	<cffunction name="fill" access="public" output="no">
		<cfargument name="html" type="string" default="">
		<cfargument name="data" type="struct" default="#StructNew()#">
		
		<!--- 
			This processes the templates and compiles them in a manner so that they become structs and arrays with positional indices of all of the template tags
			This allows us to process a template without doing regex/replace over and over and over. This creates a set of nested structures called the "context".
			Each struct contains an array of all of the tags it contains. In the regex loop we an array of contexts and pass up and down the context chain. This
			allows us to calculate once the start and end of each tag. So that iterations of it can just use stored values. This very closely mimics the construction
			seen on mustache.js.
		--->
		<cfset local.matcher = variables.tagRegex.matcher(arguments.html)>
		<cfset local.context = {
			tags = [],
			start = 1,
			inner = arguments.html,
			innerStart = 1,
			innerEnd = len(arguments.html) + 1,
			end = len(arguments.html) + 1
		}>
		<cfset local.myContext = local.context>
		<cfset local.previousContext = []>
		<cfloop condition="#local.matcher.find()#">
			<cfif local.matcher.group(1) is not "/">
				<cfset ArrayAppend(local.myContext.tags, { label = local.matcher.group(2), type = local.matcher.group(1), start = local.matcher.start() + 1, end = local.matcher.end() + 1, innerStart = local.matcher.end() + 1, innerEnd = "", inner = "", tags = [] })>
				
				<!--- for sections we need to alter the context --->
				<cfif local.matcher.group(1) is not "" && local.matcher.group(1) is not "%">
					<cfset ArrayAppend(local.previousContext, local.myContext)>
					<cfset local.myContext = local.myContext.tags[ArrayLen(local.myContext.tags)]>
				</cfif>
			<cfelse>
				<cfset local.myContext.end = local.matcher.end() + 1>
				<cfset local.myContext.innerEnd = local.matcher.start() + 1>
				<cfset local.myContext.inner = Mid(arguments.html, local.myContext.innerStart, local.myContext.innerEnd - local.myContext.innerStart)>
				<cfset local.myContext = local.previousContext[ArrayLen(local.previousContext)]>
				<cfset ArrayDeleteAt(local.previousContext, ArrayLen(local.previousContext))>
			</cfif>
		</cfloop>


		<cfreturn processTags(arguments.html, local.context, [ arguments.data ])>
	</cffunction>

	<!--- Private function, used for nested loops and recursion --->
	<cffunction name="processTags" access="private">
		<cfargument name="html">
		<cfargument name="context">
		<cfargument name="data">

		<!--- using an array and concatenating to a list is faster than string appending, at the end we ArrayToList() for max performance --->
		<cfset local.return = []>
		
		<!--- determine our current position in the template based on the innerstart of the current context --->
		<cfset local.position = arguments.context.innerstart>
		<cfloop array="#arguments.context.tags#" index="local.i">
			<!--- append everything that came prior to the tag --->
			<cfset ArrayAppend(local.return, Mid(arguments.html, local.position, local.i.start - local.position))>
			<!--- set the position to the end of this current tag, so that the next tag will pick up everything from here to there --->
			<cfset local.position = local.i.end>

			<cfif local.i.type is "-">
				<cfif ArrayLen(arguments.data) gt 1>
					<cfset local.stash = arguments.data[ArrayLen(arguments.data)]>
					<cfset ArrayDeleteAt(arguments.data, ArrayLen(arguments.data))>
					<cfset ArrayAppend(local.return, processTags(arguments.html, local.i, arguments.data))>
					<cfset ArrayAppend(arguments.data, local.stash)>
				</cfif>
				<cfcontinue>
			</cfif>

			<cfset local.data = arguments.data[ArrayLen(arguments.data)]>

			<!--- calculate the data value --->
			<cfif StructKeyExists(local.data, local.i.label)>
				<cfset local.temp = local.data[local.i.label]>
			<cfelseif IsObject(local.data) && StructKeyExists(local.data, "get" & local.i.label)>
				<!--- If working with an ORM result, we want to call the get() method on the required key --->
				<cfinvoke component="#local.data#" method="get#local.i.label#" returnvariable="local.temp">
			<cfelseif StructKeyExists(local, "temp")>
				<!--- No value, and no object getter, so we need to ensure that the previous loop did not set a value --->
				<cfset StructDelete(local, "temp")>
			</cfif>
			
			<!--- Process the different types of tags --->
			<cfif local.i.type is "" || local.i.type is "%">
				<cfif !StructKeyExists(local, "temp")>
					<!--- do nothing --->
				<cfelseif IsSimpleValue(local.temp)>
					<cfset ArrayAppend(local.return, local.i.type is "%" ? htmlEditFormat(local.temp) : local.temp)>
				<cfelseif IsStruct(local.temp) && StructKeyExists(local.temp, "template") && StructKeyExists(local.temp, "data")>
					<cfif IsArray(local.temp.data)>
						<cfloop array="#local.temp.data#" index="local.j">
							<cfset ArrayAppend(local.return, fill(local.temp.template, local.j))>
						</cfloop>
					<cfelse>
						<cfset ArrayAppend(local.return, fill(local.temp.template, local.temp.data))>
					</cfif>
				</cfif>
			<cfelseif local.i.type is "##">
				<cfif StructKeyExists(local, "temp")>
					<cfif IsArray(local.temp)>
						<cfloop array="#local.temp#" index="local.j">
							<cfset ArrayAppend(arguments.data, local.j)>
							<cfset ArrayAppend(local.return, processTags(arguments.html, local.i, arguments.data))>
							<cfset ArrayDeleteAt(arguments.data, ArrayLen(arguments.data))>
						</cfloop>
					<cfelseif IsStruct(local.temp) && !StructIsEmpty(local.temp)>
						<cfset ArrayAppend(arguments.data, local.temp)>
						<cfset ArrayAppend(local.return, processTags(arguments.html, local.i, arguments.data))>
						<cfset ArrayDeleteAt(arguments.data, ArrayLen(arguments.data))>
					</cfif>
				</cfif>
			<cfelseif local.i.type is ":">
				<cfif 
					StructKeyExists(local, "temp") && (
						(IsSimpleValue(local.temp) && local.temp is not "" && local.temp is not false) 
						||
						(IsArray(local.temp) && ArrayLen(local.temp) gt 0)
						||
						(IsStruct(local.temp) && !StructIsEmpty(local.temp))
					)
				>
					<cfset ArrayAppend(local.return, processTags(arguments.html, local.i, arguments.data))>
				</cfif>
			<cfelseif local.i.type is "!">
				<cfif (!StructKeyExists(local, "temp")
					|| (
						(IsSimpleValue(local.temp) && (local.temp is "" || local.temp is false))
						||
						(IsArray(local.temp) && ArrayLen(local.temp) is 0)
						||
						(IsStruct(local.temp) && StructIsEmpty(local.temp))
					))
				>
					<cfset ArrayAppend(local.return, processTags(arguments.html, local.i, arguments.data))>
				</cfif>
			</cfif>
		</cfloop>

		<!--- append everything that comes after all of the tags --->
		<cfif local.position lt arguments.context.end>
			<cfset ArrayAppend(local.return, mid(arguments.html, local.position, arguments.context.innerend - local.position))>
		</cfif>
		
		<!--- convert our array into a string --->
		<cfreturn ArrayToList(local.return, "")>
	</cffunction>
	
	<!--- Preserves a template, this is useful when passing an HTML template on to javascript, otherwise the template may be processed before it reaches javascript --->
	<!--- sv.templates.unpreserve() will unpreserve the template for use --->
	<cffunction name="preserve" access="public" output="no">
		<cfargument name="html">
		
		<cfreturn ReReplaceNoCase(arguments.html, "\{\{", "{{$", "all")>
	</cffunction>
</cfcomponent>