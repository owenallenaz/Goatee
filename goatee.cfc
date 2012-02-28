<cfcomponent>
	<cffunction name="init">
		<cfreturn this>
	</cffunction>
	
	<!--- Templating entry point function, this functions merges a template with it's data --->
	<cffunction name="fill" access="public" output="no">
		<cfargument name="html">
		<cfargument name="data">
		
		<cfset local.return = arguments.html>
		
		<!--- This adds a _\d identify to all tags, this allows us to properly process nested sections with the same name inside of each other --->
		<!--- Example: {{:test6}}<span>{{#test6}}{{test6}}{{/test6}}</span>{{/test6}} --->
		<cfset local.tagRegex = CreateObject("java", "java.util.regex.Pattern").compile("\{\{(##|!|:|\/)(.*?)\}\}", 32)>
		<cfset local.matcher = local.tagRegex.matcher(local.return)>
		<cfset local.tags = ArrayNew(1)>
		<cfset local.index = 1>
		<cfloop condition="#local.matcher.find()#">
			<cfset local.value = "">
			
			<cfif ListFindNoCase("##,:,!", local.matcher.group(1))>
				<cfset ArrayAppend(local.tags, { label = local.matcher.group(2), index = local.index})>
				<cfset local.return = Replace(local.return, local.matcher.group(0), Replace(local.matcher.group(0), "}}", "_#local.index#}}"))>
				<cfset local.index++>
			<cfelseif local.matcher.group(1) is "/">
				<cfset local.lastValue = local.tags[ArrayLen(local.tags)].index>
				<cfset ArrayDeleteAt(local.tags, ArrayLen(local.tags))>
				<cfset local.return = Replace(local.return, local.matcher.group(0), Replace(local.matcher.group(0), "}}", "_#local.lastValue#}}"))>
			</cfif>
		</cfloop>
		
		<cfreturn processTags(local.return, arguments.data)>
	</cffunction>

	<!--- Private function, used for nested loops and recursion --->
	<cffunction name="processTags" access="private" output="no">
		<cfargument name="html">
		<cfargument name="data">
		<cfset local.return = arguments.html>
		
		<!--- Processes all sections --->
		<cfset local.tagRegex = CreateObject("java", "java.util.regex.Pattern").compile("\{\{(##|!|:)(.*?)_(\d*?)\}\}(.*?)\{\{\/\2_\3\}\}", 32)>
		<cfset local.matcher = local.tagRegex.matcher(local.return)>
		
		<cfloop condition="#local.matcher.find()#">
			<cfset local.value = "">
		
			<cfif local.matcher.group(1) is "##" && StructKeyExists(arguments.data, local.matcher.group(2))>
				<cfif IsArray(arguments.data[local.matcher.group(2)])>
					<cfloop array="#arguments.data[local.matcher.group(2)]#" index="local.i">
						<cfset local.value &= processTags(local.matcher.group(4), local.i)>
					</cfloop>
				<cfelseif IsStruct(arguments.data[local.matcher.group(2)])>
					<cfset local.value = processTags(local.matcher.group(4), arguments.data[local.matcher.group(2)])>
				</cfif>
			<cfelseif local.matcher.group(1) is ":" && StructKeyExists(arguments.data, local.matcher.group(2))>
				<cfif 
					(IsSimpleValue(arguments.data[local.matcher.group(2)]) && arguments.data[local.matcher.group(2)] is not "" && arguments.data[local.matcher.group(2)] is not false) 
					||
					(IsArray(arguments.data[local.matcher.group(2)]) && ArrayLen(arguments.data[local.matcher.group(2)]) gt 0)	
				>
					<cfset local.value = ReReplace(local.matcher.group(0), "\{\{(:|/)" & local.matcher.group(2) & "_" & local.matcher.group(3) & "\}\}", "", "all")>
				</cfif>
			<cfelseif local.matcher.group(1) is "!" && (!StructKeyExists(arguments.data, local.matcher.group(2)) 
				|| (
					(IsSimpleValue(arguments.data[local.matcher.group(2)]) && (arguments.data[local.matcher.group(2)] is "" || arguments.data[local.matcher.group(2)] is false))
					||
					(IsArray(arguments.data[local.matcher.group(2)]) && ArrayLen(arguments.data[local.matcher.group(2)]) is 0)
				))
			>
				<cfset local.value = ReReplace(local.matcher.group(0), "\{\{(!|/)" & local.matcher.group(2) & "_" & local.matcher.group(3) & "\}\}", "", "all")>
			</cfif>
		
			<cfset local.return = Replace(local.return, local.matcher.group(0), local.value)>
			<cfset local.matcher.reset(local.return)>
		</cfloop>
		
		<!--- Fills all variable tags --->
		<cfset local.tagRegex = CreateObject("java", "java.util.regex.Pattern").compile("\{\{(\w*?)\}\}", 32)>
		<cfset local.matcher = local.tagRegex.matcher(local.return)>
		
		<cfloop condition="#local.matcher.find()#">
			<cfset local.value = "">
			
			<cfif !StructKeyExists(arguments.data, local.matcher.group(1))>
				<cfset local.value = "">
			<cfelseif IsSimpleValue(arguments.data[local.matcher.group(1)])>
				<cfset local.value = arguments.data[local.matcher.group(1)]>
			<cfelseif IsStruct(arguments.data[local.matcher.group(1)]) && StructKeyExists(arguments.data[local.matcher.group(1)], "template") && StructKeyExists(arguments.data[local.matcher.group(1)], "data")>
				<cfif IsArray(arguments.data[local.matcher.group(1)].data)>
					<cfloop array="#arguments.data[local.matcher.group(1)].data#" index="local.i">
						<cfset local.value &= fill(arguments.data[local.matcher.group(1)].template, local.i)>
					</cfloop>
				<cfelse>
					<cfset local.value = fill(arguments.data[local.matcher.group(1)].template, arguments.data[local.matcher.group(1)].data)>
				</cfif>
			</cfif>
			
			<cfset local.return = Replace(local.return, local.matcher.group(0), local.value, "all")>
		</cfloop>
		
		<cfreturn local.return>
	</cffunction>
	
	<!--- Preserves a template, this is useful when passing an HTML template on to javascript, otherwise the template may be processed before it reaches javascript --->
	<!--- goatee.unpreserve() will unpreserve the template for use --->
	<cffunction name="preserve" access="public" output="no">
		<cfargument name="html">
		
		<cfreturn ReReplaceNoCase(arguments.html, "\{\{", "{{$", "all")>
	</cffunction>
</cfcomponent>