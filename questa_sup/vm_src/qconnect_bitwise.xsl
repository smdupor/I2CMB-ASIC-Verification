<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="Cell">
    	<xsl:element name="Cell">
		<xsl:variable name="cell" select="." />
		<xsl:choose>
		  <xsl:when test="contains($cell, '(%BITWISE%)')">
		  	<xsl:value-of select='concat(substring-before($cell,"(%BITWISE%)"),"/*/",substring-after($cell,"(%BITWISE%)"))'/>
		  </xsl:when>
		  <xsl:otherwise>
			<xsl:value-of select='.'/>
		  </xsl:otherwise>
		</xsl:choose>
	</xsl:element>
</xsl:template>

<xsl:template match="node()|@*">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>
