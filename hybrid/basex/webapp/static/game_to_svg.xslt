<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:param name="playerId"/>
<xsl:param name="gameId"/>

<xsl:template match="/game/players">
</xsl:template>

<xsl:template match="/game/gamestate">
		<xsl:variable name="turn" select="@playerturn" />
		<xsl:variable name="winner" select="winner/@playerid" />
		
    <div>
			<p>you are player: <xsl:value-of select="$playerId"/></p>

	<xsl:choose>

		<xsl:when test="$winner = 1 or $winner = 2">
			<p>Winner: <xsl:value-of select="$winner"/>	</p>	
		</xsl:when>
		<xsl:otherwise>
			<p>player turn: <xsl:value-of select="$turn"/>	</p>
		</xsl:otherwise>
	</xsl:choose>
	<p>
  <xsl:variable name="w" select="100"/>
	
<svg width="{$w * 3}" height="{$w * 3}">


<xsl:for-each select="row">
  <xsl:variable name="r" select="position() - 1" />
	<xsl:for-each select="field">


	  <xsl:variable name="c" select="position() - 1" />
	  <xsl:variable name="front" select="concat('document.__endpoint.POST(&quot;http://localhost:8081/move/', $gameId, '&quot;')" />
		<xsl:variable name="link" select="concat($front, 
',{ row: ', 
$r + 1, 
', col: ', 
$c + 1, 
', playerId: ', 
$playerId,
'}, ',
$gameId,
')'
)" />

 <xsl:choose>
	<xsl:when test="@mark = 1">
	 <rect  x="{$c * $w}" y="{$r * $w}" width="{$w - 2}" height="{$w - 2}" style="fill:rgb(240,240,240)" />			
		<text x="{$c * $w + $w div 2}" y="{$r * $w + $w div 2}">X</text>
	</xsl:when>
	<xsl:when test="@mark = 2">
		 <rect  x="{$c * $w}" y="{$r * $w}" width="{$w - 2}" height="{$w - 2}" style="fill:rgb(240,240,240)" />			
		<text x="{$c * $w + $w div 2}" y="{$r * $w + $w div 2}">O</text>
	</xsl:when>
	
	<xsl:when test="$playerId = $turn">
	 <rect onclick="{$link}" x="{$c * $w}" y="{$r * $w}" width="{$w - 2}" height="{$w - 2}" style="fill:rgb(240,240,240)" />		
	</xsl:when>
	
	<xsl:otherwise>
	 <rect x="{$c * $w}" y="{$r * $w}" width="{$w - 2}" height="{$w - 2}" style="fill:rgb(240,240,240)" />	
	</xsl:otherwise>
 </xsl:choose>

	</xsl:for-each>
</xsl:for-each>

</svg></p></div>
</xsl:template>

</xsl:stylesheet>
