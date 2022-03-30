<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
>

<xsl:output method="xml" indent="yes"/>

<!--
	This stylesheet converts the "abbreviated" Excel 2003 XML format (where empty
	cells are omitted from the data output) to a "canonical" format in which all
	cells are represented even if they are empty. (JLL 29 Apr 2008)
	-->

<!-- BEGIN USER MODIFICATION AREA -->

<!--
	The "first-col" variable may contain the (1-based) index of the first column
	of the spreadsheet which is used for real testplan data. If this value is not
	supplied, the stylesheet will attempt to figure it out by looking at the data
	set to try to find the first non-blank column.
	-->

<xsl:variable name="first-col"></xsl:variable><!-- minimum real column -->

<!--
	The "max-jump" variable contains the maximum number of replacement cells this
	stylesheet will insert. This is to prevent a runnaway situation where the last
	cell in a row is given a very high number (256 in the case of OpenOffice).
	-->

<xsl:variable name="max-jump">20</xsl:variable><!-- maximum column jump -->

<!-- END USER MODIFICATION AREA -->

<!--
	This template handles spreadsheet tags of the spreadsheet. We need to recalculate
	skip-col per sheet.
	-->

<xsl:template match="ss:Worksheet/ss:Table">
	<xsl:variable name="skip-col">
    <xsl:choose>
      <!-- user-specified value takes priority -->
      <xsl:when test="string($first-col)">
        <xsl:value-of select="$first-col - 1"/>
      </xsl:when>
      <xsl:otherwise>
		    <xsl:for-each select="(ss:Row/ss:Cell[1]/ss:Data[1])[1]">
			    <xsl:choose>
				    <!-- grab starting column, if specified -->
				    <xsl:when test="string(../@ss:Index)">
					    <xsl:value-of select="../@ss:Index - 1"/>
				    </xsl:when>
				    <!-- or, start in column one by default -->
				    <xsl:otherwise>0</xsl:otherwise>
			    </xsl:choose>
		    </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
	</xsl:variable>
	<xsl:copy>
		<xsl:apply-templates select="ss:Row">
			<xsl:with-param name="skip-col" select="$skip-col"/>
		</xsl:apply-templates>
	</xsl:copy>
</xsl:template>

<!--
	This template handles a single row of the spreadsheet. We need to handle Rows
	seperately because only the first cell should be passed from this level.. the
	other cells in the row are handles in a chain by the ss:Cell template.
	-->

<xsl:template match="ss:Row">
	<xsl:param name="skip-col"/>
	<xsl:copy>
		<xsl:apply-templates select="@*"/>
		<xsl:apply-templates select="ss:Cell[1]">
			<xsl:with-param name="column" select="1"/>
			<xsl:with-param name="skip-col" select="$skip-col"/>
		</xsl:apply-templates>
	</xsl:copy>
</xsl:template>

<!--
	This template makes sure that any skipped cells are reinstated.
	-->

<xsl:template match="ss:Cell">
	<xsl:param name="column"/>
	<xsl:param name="skip-col"/>
	<xsl:variable name="actual-col">
		<xsl:choose>
			<xsl:when test="(string-length(@ss:Index) = 0) or (number(@ss:Index) &lt;= number($column))">
				<xsl:value-of select="$column"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@ss:Index"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="number($actual-col) &gt; number($skip-col)">
			<xsl:variable name="dummy-cells">
				<xsl:value-of select="number($actual-col) - number($column) - number($skip-col)"/>
			</xsl:variable>
			<!-- Process "ss:Cell" elements one-by-one, counting each time -->
			<xsl:if test="(number($dummy-cells) &gt;= 1) and (number($dummy-cells) &lt;= number($max-jump))">
				<xsl:call-template name="extra-cells">
					<xsl:with-param name="n" select="$dummy-cells"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
			</xsl:copy>
			<xsl:apply-templates select="following-sibling::*[1]">
				<xsl:with-param name="column">
					<xsl:value-of select="number($actual-col) + 1"/>
				</xsl:with-param>
				<xsl:with-param name="skip-col" select="0"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="following-sibling::*[1]">
				<xsl:with-param name="column">
					<xsl:value-of select="number($actual-col) + 1"/>
				</xsl:with-param>
				<xsl:with-param name="skip-col">
					<xsl:value-of select="number($skip-col)"/>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="extra-cells">
	<xsl:param name="n"/>
	<xsl:if test="number($n) &gt; 0">
		<Cell/><!-- Adding extra cell (DO NOT use a namespace on this element) -->
		<xsl:call-template name="extra-cells">
			<xsl:with-param name="n" select="number($n) - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!--
	This template ensures that any elements not addressed above are passed through.
	-->

<xsl:template match="node()|@*">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>
