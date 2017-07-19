var WebSocketServer = require('ws').Server
var wss = new WebSocketServer({ port: 7080 });

var express = require('express');
var path = require('path');
var bodyParser = require('body-parser')
var app = express();
var MongoClient = require('mongodb').MongoClient

var db = {}

app.use( bodyParser.json() );
app.use(bodyParser.urlencoded({ 
    extended: true
})); 


var connectedSockets = []
// {signal:[channel]}
var subscribedChannels = {}

wss.on('connection', function connection(ws) {
    console.log('got websocket connection');
    connectedSockets.push(ws)
    ws.on("message", function(message) {
	console.log("got ws message!")
	message = JSON.parse(message)
	
	if (message.type == "subscribe") {
	    for (s in message.data) {
		var signal = message.data[s]
		subscribedChannels[signal] = subscribedChannels[signal] || []
		subscribedChannels[signal].push(ws)
	    }
	}
    });
    
    ws.on("close", function(code, reason){
	for (c in subscribedChannels) {
	    var wsInChannel = subscribedChannels[c]
	    var index = wsInChannel.indexOf(ws)
	    if (index != -1) {
		console.log("removed ws from subscribers")
		subscribedChannels[c].splice(index, 1)
	    }
	}
	
	connectedSockets.splice(connectedSockets.indexOf(ws), 1);
	console.log("removed ws from connected channels")
	console.log(connectedSockets.length + " are still connected");
    });
})

//push game via websocket
function pushGame(game, toId) {
    var wsInChannel = subscribedChannels[toId] || []
    console.log("subscriptions for " + toId + ": " + wsInChannel.length)
    for (c in wsInChannel) {
	console.log("sending game to channel " + toId)
	wsInChannel[c].send(JSON.stringify(game));
    }
}


function Game() {
    this.id = 0;
    this.rows = [[0,0,0],[0,0,0],[0,0,0]];
    this.playerTurn = 1;
    this.playerWin = 0;
    this.full = false;
}

//return list of games from database
function allOpenGames(callback) {
    db.collection('ttt').find({}).toArray().then(function(allGames){
	callback(allGames)
    })
}


//fetch game from database
function gameForId(gameId, callback) {
    //dbload here
    console.log(gameId)
    db.collection("ttt").findOne({"id": parseInt(gameId)}, function(err, doc) {
	if (err) {
	    console.log(err)
	    console.log("error")
	    callback(undefined)
	    return;
	} else {
	    console.log(doc)
	    callback(doc)
	}
    })
}

//update game in database
function updateGame(game, callback) {
    db.collection('ttt').replaceOne({"id" : game.id}, game).then(function(result){
	callback()
    }).catch(function(err){
	console.log(err)
    });
    //dbsave here
};

//create game in database and return
function createGame(callback) {
    db.collection("ttt").find({}).count().then(function(count){
	var game = new Game();
	game.id = count + 1
	
	db.collection("ttt").save(game, function(err, result){
	    if (err) console.log(err)
	    console.log("saved")
	    console.log(game)
	    callback(game)
	});

    })

}


//only check row and col with new mark
function gameWon(game, playerId) {
    var rows = game.rows
    function checkHV(columns) {
	for (c = 0; c < 3; c++) {
	    var found = true
	    for(r = 0; r < 3; r++) {
		if (columns) {
		    if (rows[r][c] != playerId) {
			found = false
			break
		    }
		} else {
		    if (rows[c][r] != playerId) {
			found = false
			break
		    }
		}
	    }
	    if (found == true) {
		console.log((columns ? "col" : "row") + " matches")
		return playerId
	    }
	}
	return 0
    }

    if (checkHV(true) != 0) {
	return playerId
    }
    if (checkHV(false) != 0) {
	return playerId
    }    

    //diagonal
    if ((rows[0][0] == playerId && rows[1][1] == playerId && rows[2][2] == playerId)
	|| (rows[2][0] == playerId && rows[1][1] == playerId && rows[0][2] == playerId)) {
	return playerId
    }
    
    return 0
}
function handleMove(game, row, col, playerId, callback) {
    if(game.rows[row][col] != 0) {
	callback(false)
    }
    
    game.rows[row][col] = playerId

    //check win
    var playerWin = gameWon(game, playerId)
    
    if (playerWin == 0) {
	if (game.playerTurn == 1) {
	    game.playerTurn = 2
	} else {
	     game.playerTurn = 1
	}
    } else {
	game.playerTurn = 0;
	game.playerWin = playerWin;
    }
    
    updateGame(game, function(){
	pushGame(game, game.id);
	callback(true)
    });
}

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', function(req, res) {
    res.sendFile('main.html');
});

app.post('/create', function(req, res){
    console.log('post to create')
    createGame(function(game){
	res.send(game)
    })
    
})

app.post('/join/:gameId', function(req, res){
    console.log('post to join')
    var gameId = req.params.gameId
    gameForId(gameId, function(game) {
	
	if (game == undefined) {
	    res.send("invalid game")
	    return
	}
	
	game.full = true
	updateGame(game, function(){
	    console.log("pushing game")
	    pushGame(game, game.id);    
	    res.send(game)
	})
	
    })	
})

app.post('/move/:gameId', function(req, res){
    var gameId = req.params.gameId
    console.log('post to move for game ' + gameId);
    var row = req.body.row
    var col = req.body.col
    var playerId = req.body.playerId

    //check if move allowed
    gameForId(gameId, function(game){
	if (game == undefined) {
	    res.send('unkown game');
	    return
	}

	handleMove(game, row, col, playerId, function(allowed){
	    if (allowed) {
	    res.send('updated server');
	} else {
	    res.send('invalid move');
	}
	})
	
    })
    

});

app.get('/listgames', function(req, res) {
    allOpenGames(function(games){
	res.send(games);
    })
});

MongoClient.connect("mongodb://localhost:27017/ttt", function(err, database){
    if (err) console.log(err)
    db = database
    
    app.listen(7001, function () {
	console.log('Tick Tack Toe server listening on port 7001');
    });
    
});

