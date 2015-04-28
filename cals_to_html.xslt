<!DOCTYPE xsl:stylesheet [<!ENTITY nbsp "&#160;">]>
<xsl:stylesheet version="2.0"
   xmlns:xsl=     "http://www.w3.org/1999/XSL/Transform"
   xmlns:xs=      "http://www.w3.org/2001/XMLSchema"
   xmlns:local   ="http://127.0.0.1/cals_to_html.xslt"
   >
<!-- (c) john mullee 2004 - copyright placed in the public domain

	Needs Saxon implementation that handles XSLT-2, e.g.
		http://sourceforge.net/projects/saxon/files/Saxon-HE/9.3/saxonhe9-3-0-5j.zip/download

-->

   <xsl:output
     method                  = "html"
     doctype-public          = "-//W3C//DTD HTML 4.01 Transitional//EN"
     encoding                = "UTF-8"
     escape-uri-attributes   = "yes"
     include-content-type    = "yes"
     indent                  = "yes"
     />
<!--
   CALS Table Model
      http://www.oasis-open.org/specs/a502.htm
      http://www.oasis-open.org/cover/tr9502.html
   OASIS XML Exchange Table Model
      http://www.oasis-open.org/specs/a503.htm
      http://www.oasis-open.org/specs/tm9901.htm
   Some test cases:
      http://sources.redhat.com/ml/xsl-list/2001-07/msg00835.html
       * Subject: Re: [xsl] Table formatting challenge
       * From: Norman Walsh <ndw at nwalsh dot com>
      ".. Here are a few more examples (that thwart the code you presented)" 
-->

   <xsl:template match="node()|@*" mode="html-only" xpath-default-namespace="http://www.w3.org/1999/xhtml">
      <xsl:message>(node)</xsl:message>
      <xsl:choose>
         <xsl:when test="compare(local-name(), name())=0">
            <xsl:copy copy-namespaces="no">
	      <xsl:message>(node1)</xsl:message>
               <xsl:apply-templates select="@*|node()" mode="html-only"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
	      <xsl:message>(node2)</xsl:message>
            <xsl:apply-templates select="node()" mode="html-only"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="/">
      <xsl:message>(root)</xsl:message>
      <html>
         <head>
            <style type="text/css">
               td.generated { background-color: green; }
            </style>
         </head>
         <body>
            <xsl:apply-templates/>
         </body>
      </html>
   </xsl:template>

   <!-- ===================== -->
   <!-- dummy for Jakob's xml -->
      <xsl:template match="para">
         <xsl:message>(para)</xsl:message>
         <xsl:choose>
            <xsl:when test="count(node()) > 0">
               <p>
                  <xsl:apply-templates/>
               </p>
            </xsl:when>
            <xsl:otherwise>&nbsp;</xsl:otherwise>
         </xsl:choose>
      </xsl:template>
      <xsl:template match="anote"><a href="#{@refid}">(LINK <xsl:apply-templates/>)</a></xsl:template>
      <xsl:template match="note"><a name="{@id}"/><xsl:apply-templates/></xsl:template>
   <!-- ===================== -->

   <!-- CHANGE xsl:template match="informaltable"-->
   <xsl:template match="table">
      <xsl:message>(table)</xsl:message>
      <xsl:apply-templates select="tgroup" mode="XML_ExTabModel"/>
   </xsl:template>

   <!-- XML_ExTabModel mode -->

   <xsl:template match="tgroup" mode="XML_ExTabModel">
      <xsl:message>(tgroup)</xsl:message>
      <table border="1" summary="">
         <caption>
            <!-- not part of XML_ExTabModel -->
         </caption>
         <colgroup span="{@cols}">
            <xsl:for-each select="colspec">
               <col span="1" width="{@colwidth}">
                  <xsl:call-template name="general_cell_alignment">
                     <xsl:with-param name="element" select="."/>
                  </xsl:call-template>
               </col>
            </xsl:for-each>
         </colgroup>
         <xsl:apply-templates select="thead"   mode="XML_ExTabModel"/>
         <tfoot>
            <!-- not part of XML_ExTabModel -->
         </tfoot>
         <xsl:apply-templates select="tbody"   mode="XML_ExTabModel"/>
      </table>

   </xsl:template>

   <xsl:template match="thead" mode="XML_ExTabModel">
      <xsl:message>(thead)</xsl:message>
      <thead>
         <xsl:call-template name="general_cell_alignment">
            <xsl:with-param name="element" select="."/>
         </xsl:call-template>
         <xsl:call-template name="recursive_row_processor">
            <xsl:with-param name="set_of_rows" select="row"/>
         </xsl:call-template>
      </thead>
   </xsl:template>

   <xsl:template match="tbody" mode="XML_ExTabModel">
      <xsl:message>(tbody)</xsl:message>
      <tbody>
         <xsl:call-template name="general_cell_alignment">
            <xsl:with-param name="element" select="."/>
         </xsl:call-template>
         <xsl:call-template name="recursive_row_processor">
            <xsl:with-param name="set_of_rows" select="./row"/>
         </xsl:call-template>
      </tbody>
   </xsl:template>

   <!-- ===== recursive row processing ======= -->

   <xsl:template name="recursive_row_processor">
      <xsl:param name="curr_row"    as="xs:integer" select="1"/>
      <xsl:param name="set_of_rows" as="element()*" />
      <xsl:variable name="num_rows" select="count(./row)"/>
      <xsl:message>recursive_row_processor, $num_rows=<xsl:value-of select="$num_rows"/>, $curr_row=<xsl:value-of select="$curr_row"/></xsl:message>
      <!-- add a new row to set -->
      <xsl:variable name="new_set_of_rows" as="element()*">
         <xsl:copy-of select="$set_of_rows"/>
         <xsl:apply-templates select="./row[$curr_row]" mode="XML_ExTabModel">
            <!-- generated rows are forwarded to cell generator for rowspan lookup -->
            <xsl:with-param name="set_of_rows" select="$set_of_rows"/>
         </xsl:apply-templates>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="$curr_row = $num_rows">
            <!-- terminate recursion, output rows -->
            <!-- copy without local-namespace stuff -->
            <xsl:apply-templates select="$new_set_of_rows" mode="html-only"/>
         </xsl:when>
         <xsl:otherwise>
            <!-- tail-recurse for more rows -->
            <xsl:call-template name="recursive_row_processor">
               <xsl:with-param name="curr_row" select="xs:integer($curr_row + 1)"/>
               <xsl:with-param name="set_of_rows" select="$new_set_of_rows"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:template>

   <xsl:template match="row" mode="XML_ExTabModel">
      <xsl:param name="set_of_rows" as="element()*" />
      <xsl:message>(row)</xsl:message>
      <tr>
         <xsl:if test="ancestor::thead">
            <xsl:attribute name="bgcolor" select="'#999999'"/>
         </xsl:if>
         <xsl:call-template name="general_cell_alignment">
            <xsl:with-param name="element" select="."/>
         </xsl:call-template>
         <xsl:call-template name="recursive_cell_processor">
            <xsl:with-param name="set_of_rows" select="$set_of_rows" />
         </xsl:call-template>
      </tr>
   </xsl:template>

   <!-- ===== recursive cell processing ======= -->
   <xsl:template name="recursive_cell_processor">
      <xsl:param name="curr_entry"   as="xs:integer" select="1"/>
      <xsl:param name="curr_column"  as="xs:integer" select="1"/>
      <xsl:param name="set_of_cells" as="element()*"/>
      <xsl:param name="last_cell"    as="document-node()?"/>
      <xsl:param name="set_of_rows"  as="element()*"/>

      <xsl:message>(recursive_cell_processor)</xsl:message>

      <xsl:variable name="num_columns" select="../../@cols"/>
      <xsl:variable name="num_entries" select="count(entry)"/>
      <xsl:variable name="current_row" select="count($set_of_rows) + 1"/>

      <xsl:variable name="cells_spanning_rows">
        <xsl:message>(: cells_spanning_rows)</xsl:message>
         <!-- build a list of row-spanning cells which will affect this row -->
         <xsl:for-each select="$set_of_rows[ td/@rowspan >= ($current_row - position()) ]">
            <!-- context = TR containing a cell which rowspans across current row -->
            <xsl:variable name="row_id" select="generate-id(.)"/>
            <!-- BUG this relies on id-strings Collating in document-order : saxon 7 works -->
            <xsl:variable name="rowndx" select="count($set_of_rows[$row_id > generate-id(.)])" as="xs:integer"/>
            <xsl:for-each select="td[@rowspan]">
               <!-- context = TD's containing rowspan -->
               <xsl:if test="(@rowspan + $rowndx) >= $current_row">
                  <!-- TD's which spans across current row -->
                  <xsl:for-each select="@local:beg to @local:end">
                     <span col="{.}"/>
                  </xsl:for-each>
               </xsl:if>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>

      <!-- adjust for the special case of the first column being overlapped -->
      <xsl:variable name="adjusted_curr_column_list" as="xs:integer+">
         <xsl:message>(: adjusted_curr_column_list)</xsl:message>
         <xsl:choose>
            <xsl:when test="count($cells_spanning_rows/span[@col = $curr_column]) > 0">
               <!-- build a list of col numbers which follow contiguous series' of col numbers -->
               <xsl:for-each select="$cells_spanning_rows/span"><xsl:sort select="number(@col)"/>
                  <xsl:choose>
                     <xsl:when test="following-sibling::node()[1]/@col">
                        <xsl:if test="not(xs:integer(@col) = xs:integer(following-sibling::node()[1]/@col - 1))">
                           <xsl:value-of select="@col + 1"/>
                        </xsl:if>
                        <!-- otherwise, context is within contiguous series -->
                     </xsl:when>
                     <xsl:otherwise><xsl:value-of select="@col + 1"/></xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$curr_column"/></xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="adjusted_curr_column" as="xs:integer" select="$adjusted_curr_column_list[1]"/>
         <xsl:message>(: adjusted_curr_column)</xsl:message>

      <!-- build another table cell -->
      <xsl:variable name="built_cell" as="document-node()">
         <xsl:message>(: built_cell)</xsl:message>
         <xsl:call-template name="build_table_cell">
            <xsl:with-param name="entry"       select="entry[$curr_entry]"/>
            <xsl:with-param name="curr_column" select="$adjusted_curr_column"/>
         </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="next_cell_start" select="$built_cell/td/@local:beg"/>
      <xsl:variable name="next_cell_end"   select="$built_cell/td/@local:end"/>
      <xsl:variable name="last_cell_end"   select="$last_cell/td/@local:end"/>
      <xsl:variable name="num_prev_cells"  select="count($set_of_cells[name()='td'])"/>

      <!-- add new cell to existing set of cells -->
      <xsl:variable name="new_set_of_cells">
         <xsl:message>(: new_set_of_cells)</xsl:message>
         <!-- insert any cells needed at beginning of row -->
            <xsl:if test="($curr_entry = 1) and ($next_cell_end > 1)">
               <xsl:call-template name="add_empty_cells">
                  <xsl:with-param name="count" select="xs:integer($built_cell/td/@local:beg - 1)"/>
                  <xsl:with-param name="cells_spanning_rows" select="$cells_spanning_rows"/>
                  <xsl:with-param name="start" select="xs:integer(1)"/>
               </xsl:call-template>
            </xsl:if>
         <!-- emit the previously-generated cells -->
            <xsl:copy-of select="$set_of_cells"/>
         <!-- fill in any gap between prev cell and this -->
            <xsl:if test="($num_prev_cells > 0) and ($next_cell_start > ($last_cell_end + 1))">
               <xsl:call-template name="add_empty_cells">
                  <xsl:with-param name="count" select="xs:integer($next_cell_start - ($last_cell_end + 1) )"/>
                  <xsl:with-param name="cells_spanning_rows" select="$cells_spanning_rows"/>
                  <xsl:with-param name="start" select="xs:integer($last_cell_end + 1)"/>
               </xsl:call-template>
            </xsl:if>
         <!-- emit the cell we just generated -->
            <xsl:copy-of select="$built_cell"/>
         <!-- last entry: insert any cells needed at end of row -->
            <xsl:if test="($curr_entry = $num_entries) and ($next_cell_end &lt; $num_columns)">
               <xsl:call-template name="add_empty_cells">
                  <xsl:with-param name="count" select="xs:integer($num_columns - $next_cell_end)"/>
                  <xsl:with-param name="cells_spanning_rows" select="$cells_spanning_rows"/>
                  <xsl:with-param name="start" select="xs:integer($built_cell/td/@local:end + 1)"/>
               </xsl:call-template>
            </xsl:if>
      </xsl:variable>

<xsl:message>set_of_cells='<xsl:copy-of select="$set_of_cells"/>'"<xsl:value-of select="$set_of_cells"/>"</xsl:message>

      <xsl:variable name="new_set_of_cells_AS_ELEM" as="element()*">
         <xsl:apply-templates select="$new_set_of_cells" mode="DN2ELEM"/>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="not($curr_entry = $num_entries)">
            <xsl:message>(= tail-recurse for more cells)</xsl:message>
            <!-- tail-recurse for more cells -->
            <xsl:call-template name="recursive_cell_processor">
               <xsl:with-param name="curr_entry"   select="$curr_entry + 1"/>
               <xsl:with-param name="curr_column"  select="xs:integer($next_cell_end + 1)"/>
               <xsl:with-param name="set_of_cells" select="$new_set_of_cells_AS_ELEM"/>
               <xsl:with-param name="last_cell"    select="$built_cell"/>
               <xsl:with-param name="set_of_rows"  select="$set_of_rows"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message>(= terminate recusion, output cells)</xsl:message>
            <!-- terminate recusion, output cells -->
            <xsl:copy-of select="$new_set_of_cells"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:template>

   <xsl:template match="node()" mode="DN2ELEM">
      <xsl:copy-of select="node()[1]"/>
   </xsl:template>

   <!-- ===== column numbering ======= -->
   <xsl:function name="local:fn_get_col_number" as="xs:integer">
      <xsl:param name="context_tgroup"/>
      <xsl:param name="colname"/>
      <xsl:param name="default" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="$colname">
            <xsl:choose>
               <xsl:when test="$context_tgroup/colspec[@colname=$colname]/@colnum">
                  <xsl:value-of select="xs:integer($context_tgroup/colspec[@colname=$colname]/@colnum)"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- BUG there might be no preceding colspec -->
                  <xsl:value-of select="count($context_tgroup/colspec[@colname=$colname]/preceding-sibling::*[name()='colspec'])+1"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise><xsl:value-of select="$default"/></xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!-- ===== adding empty cells ======= -->
   <xsl:template name="add_empty_cells">
      <xsl:param name="count" as="xs:integer" select="0"/>
      <xsl:param name="start" as="xs:integer" select="0"/>
      <xsl:param name="cells_spanning_rows"/>
      <xsl:for-each select="$start to ($start + $count - 1)">
         <xsl:variable name="col_index" select="." as="xs:integer"/>
         <xsl:if test="count($cells_spanning_rows/span[@col = $col_index]) = 0">
            <td class="generated" local:beg="{$start + position()}" local:end="{$start + position()}">&nbsp;</td>
         </xsl:if>
      </xsl:for-each>
   </xsl:template>

   <!-- ===== table cell ======= -->
   <xsl:template name="build_table_cell">
      <xsl:param name="entry"/>
      <xsl:param name="curr_column"/>

      <xsl:variable name="start_col_pos" select="local:fn_get_col_number($entry/ancestor::tgroup, $entry/@namest,  $curr_column)"/>
      <xsl:variable name="end_col_pos"   select="local:fn_get_col_number($entry/ancestor::tgroup, $entry/@nameend, $start_col_pos)"/>

      <xsl:variable name="computed_col_span" select="xs:integer(($end_col_pos - $start_col_pos) + 1)"/>

      <!-- output results element and TD -->
	<xsl:document>
	      <td local:beg="{$start_col_pos}" local:end="{$end_col_pos}">
		 <xsl:call-template name="general_cell_alignment">
		    <xsl:with-param name="element" select="$entry"/>
		 </xsl:call-template>
		 <!-- colspan -->
		 <xsl:if test="$computed_col_span > 1">
		    <xsl:attribute name="colspan">
		       <xsl:value-of select="$computed_col_span"/>
		    </xsl:attribute>
		 </xsl:if>
		 <!-- rowspan -->
		 <xsl:if test="$entry/@morerows">
		    <xsl:if test="number($entry/@morerows)>0">
		       <xsl:attribute name="rowspan">
		          <xsl:value-of select="number($entry/@morerows)+1"/>
		       </xsl:attribute>
		    </xsl:if>
		 </xsl:if>
		 <!-- nbsp for empty cells -->
		 <xsl:if test="count($entry/node()) = 0"><xsl:text>&nbsp;</xsl:text></xsl:if>
		 <!-- proceed in Non-XML_ExTabModel mode -->
		 <xsl:apply-templates select="$entry"/>
	      </td>
	</xsl:document> 

   </xsl:template>

   <!-- ===== alignment attributes ======= -->
   <xsl:template name="general_cell_alignment">
      <xsl:param name="element"/>

      <xsl:if test="$element/@align">
         <xsl:attribute name="align">
            <xsl:choose>
               <xsl:when test="string-length(string($element/@align))>0">
                  <xsl:value-of select="replace($element/@align,'justify','left')"/>
               </xsl:when>
               <xsl:otherwise>center</xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$element/@valign">
         <xsl:attribute name="valign">
            <xsl:choose>
               <xsl:when test="string-length(string($element/@valign))>0"><xsl:value-of select="$element/@valign"/></xsl:when>
               <xsl:otherwise>top</xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$element/@char">
         <xsl:attribute name="char">
            <xsl:choose>
               <xsl:when test="string-length(string($element/@char))>0"><xsl:value-of select="$element/@char"/></xsl:when>
               <xsl:otherwise>%</xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$element/@charoff">
         <xsl:attribute name="charoff">
            <xsl:choose>
               <xsl:when test="string-length(string($element/@charoff))>0"><xsl:value-of select="$element/@charoff"/></xsl:when>
               <xsl:otherwise>3</xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
      </xsl:if>
      <xsl:if test="$element/@width">
         <xsl:attribute name="width">
            <xsl:choose>
               <xsl:when test="string-length(string($element/@width))>0"><xsl:value-of select="$element/@width"/></xsl:when>
               <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>
