(:~
 : This module contains some basic examples for RESTXQ annotations
 : @author BaseX Team
 :)
module namespace page = 'http://basex.org/modules/web-page';



(: creates a new game, only called once per game:)
declare
	%updating
  %rest:path("/create")
  %rest:POST
  function page:create-game()
{
		let $db := db:open("ttt_db")
		let $newId := count($db/games/game) + 2
		let $newPath := concat("/board/", $newId, "/1")
		let $entry := page:createGame($newId)
		return (
			db:output(web:redirect($newPath)),
							insert node $entry as last into $db/games
							)
};
(: helper method, returns an empy game:)
declare function page:createGame($gameId) {
let $game :=
 <game id="{$gameId}">
    <players>
        <player id="1">
            <name>Player 1</name>
        </player>
        <player id="2">
            <name>Player 2</name>
        </player>
    </players>
    <gamestate playerturn="1">
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
    </gamestate>
</game>
return $game
};




(: only called once at gamestart, forwarded from /create/game :)
declare
	%rest:path("board/{$gameId}/{$playerId}")
  %output:method("xhtml")
	%rest:GET
	function page:board($gameId as xs:string, $playerId)
	{
		let $db := db:open("ttt_db")
		return page:htmlWithGameIdAndPlayerId($gameId, $playerId)
};


declare function page:htmlWithGameIdAndPlayerId($gameId, $playerId) {
	let $html := <html>
		<head>
    <script type="text/javascript" src="https://code.jquery.com/jquery-1.12.0.min.js"></script>
    <script type="text/javascript" src="../../static/Endpoint/wsclient.js"></script>		
		<script src="../../static/Endpoint/endpoint.js"></script>
		<script src="../../static/game.js"></script>
		<script>
			var gameId = { $gameId };
			var playerId = { $playerId };
			start()
		</script>
		</head>
		<body>
			<div id="board"></div>
			</body>		
	</html>
	return $html
};

declare
	%updating
	%rest:POST	
	%rest:path("move/{$gameId}")
	
  %rest:form-param("row","{$row}")
  %rest:form-param("col","{$col}")
  %rest:form-param("playerId","{$playerId}")	
	function page:move(
	$gameId,
		$row,
		$col,
		$playerId)
	{
			let $db := db:open("ttt_db")	
			let $newPath := concat("gamestate/", $gameId) (: , "row", $row, "col", $col, "playerid", $playerid :)
			return	(
				db:output(web:redirect($newPath)),
				page:_playerMove($db/games/game[@id = $gameId], $playerId, $row, $col)
			)
	};


declare updating function page:_playerMove($game, $playerId, $row, $col) {
	if (page:_checkWinner($game/gamestate, $playerId, $row, $col) = 0) then
	(
		page:_togglePlayer($game/gamestate),
		page:_markField($game/gamestate/row[position() = $row]/field[position() = $col], $playerId)
	) else (
		page:_markWinner($game, page:_checkWinner($game/gamestate, $playerId, $row, $col)),
		page:_markField($game/gamestate/row[position() = $row]/field[position() = $col], $playerId)
	)
};

declare updating function page:_markWinner($game, $winningPlayer) {
	replace value of node $game/gamestate/@playerturn with 0,
	insert node <winner playerid="{$winningPlayer}"/> as first into $game/gamestate
};

declare function page:_checkWinner($gamestate, $playerId, $row, $col) {
	let $winner := 0
	let $copied := page:_copyMarkRowCol($gamestate, $playerId, $row, $col)
	return (
	if (
	(page:_fieldValue($copied, $row, 1) = $playerId and
	page:_fieldValue($copied, $row, 2) = $playerId and
	page:_fieldValue($copied, $row, 3) = $playerId)
	or
	(page:_fieldValue($copied, 1, $col) = $playerId and
	page:_fieldValue($copied,  2, $col) = $playerId and
	page:_fieldValue($copied,  3, $col) = $playerId)
	or
	(page:_fieldValue($copied, 1, 1) = $playerId and
	page:_fieldValue($copied,  2, 2) = $playerId and
	page:_fieldValue($copied,  3, 3) = $playerId)
	or
	(page:_fieldValue($copied, 1, 3) = $playerId and
	page:_fieldValue($copied,  2, 2) = $playerId and
	page:_fieldValue($copied,  3, 1) = $playerId)
)

then
		($playerId)
		else
		(0)
)
};

declare function page:_copyMarkRowCol($gamestate, $playerId, $row, $col) {
	copy $marked := $gamestate
	modify (
		replace value of node $marked/row[position() = $row]/field[position() = $col]/@mark with $playerId
	)
	return $marked
};


declare function page:_fieldValue($gamestate, $row, $col) {
	let $value := $gamestate/row[position() = $row]/field[position() = $col]/@mark
	return $value
};


declare updating function page:_markField($field, $playerId) {
		replace value of node $field/@mark with $playerId
};

declare updating function page:_togglePlayer($gamestate) {
	if ($gamestate/@playerturn = 1) then
	(replace value of node $gamestate/@playerturn with 2)
	else
	(replace value of node $gamestate/@playerturn with 1)
};


(: a redirect here from /move/ should trigger the websocket:)
declare
%rest:path("gamestate/{$boardId}")
%rest:GET
function page:gamestate($boardId as xs:string)
{
		let $db := db:open("ttt_db")
		return $db/games/game[@id = $boardId]
};

(:
    <gamestate playerturn="1">
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
        <row><field mark="0"/><field mark="0"/><field mark="0"/></row>
    </gamestate>
:)

declare
	%rest:path("")
  %output:method("xhtml")	
	%rest:GET
	function page:index()
	{
	let $x := 1
	return
	<html>
			<head>
			</head>
			<body>
			<form action="create" method="POST">
				<input type="submit" value="Create a new game" />
			</form>
			<h2>Open Games</h2>
				{
					for $g in db:open("ttt_db")/games/game
					return <div>
					<a href="http://localhost:8984/board/{ $g/@id/string(.) }/2">join</a>  <span>{$g/text() } with id: { $g/@id/string(.) }</span>
					</div>
				}
			</body>
			</html>
};



(: db initialization :)
declare
	%updating 
	%rest:path("/initdb")
	%rest:GET
	function page:initdb()
	{
			let $x := 1
			return (
			db:create("ttt_db",
			<games>
			</games>, "gamedb"),
			db:output(web:redirect("/createddb"))
			)
};

declare
	%rest:path("/createddb")
	%rest:GET
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
  %output:doctype-public("HTML")
	function page:createddb() as element(html)
	{

		let $games := db:open("ttt_db")
		return <html><h1>created dbs</h1>: { $games }</html>
};

declare
%rest:path("/showdb")
%rest:GET
function page:showdb()
{
	db:open("ttt_db")
};



declare
	%rest:path("/dbtest")
	%rest:GET
	function page:testdb()
	{
			
};

declare
	%rest:path("debug")
	%rest:GET
	function page:debug() {
		let $db := db:open("ttt_db")
		let $field := $db/games/game[@id = 10]/gamestate/row[1]/field[1]
		return $field
};

declare
updating
	%rest:path("debug2")
	%rest:POST
	function page:debug2() {
		let $db := db:open("ttt_db")
		let $field := $db/games/game[@id = 10]/gamestate/row[1]/field[1]

		return (
					db:output(<d>done</d>),

					replace value of node $field/@mark with 1
		)
};
