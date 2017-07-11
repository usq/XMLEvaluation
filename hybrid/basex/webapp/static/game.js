
function start() {
    var endpoint = Endpoint();
    var config = {ws_path: "ws://localhost:8080", use_router: true}
    var subscriptions = [gameId]
    
    function transformResponseAndInsert(response) {
	var xslParams = {"gameId": gameId, "playerId": playerId}
	
	response.transform("../../static/game_to_svg.xslt", xslParams, function(board) {
	    document.getElementById("board").innerHTML = board.raw
	});
    }
    
    endpoint.start(config, subscriptions, transformResponseAndInsert);

    endpoint.GET("../../gamestate/" + gameId, transformResponseAndInsert);
}
