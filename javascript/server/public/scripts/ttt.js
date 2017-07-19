
var TTTController = function($scope, $http, $websocket, $route, $location) {
    $scope.games = [];
    $scope.currentGame = {}
    console.log("TTTController")

    var checkWebSocket = function() {
	if ($location.path() == '/game') {
	    console.log("establishing ws connection")
	    var ws = $websocket('ws://localhost:7080');
	    ws.onOpen(function(){
		console.log("established connection");
		this.send({type:"subscribe", data:[$scope.currentGame.id]})
	    });
	    
	    ws.onMessage(function(message) {
		console.log(message)
		$scope.currentGame = JSON.parse(message.data);
	    });
	}
    }

    $scope.clicked = function(row, col) {
	var g = $scope.currentGame.rows
	if (g[row][col] == 0 &&
	    $scope.currentGame.playerTurn == $scope.playerId
	    && $scope.currentGame.full) {
	    console.log("allowed to make a mark, calling server..")
	    $http({method: "POST",
		   url: "/move/" + $scope.currentGame.id,
		   data: {row: row, col: col, playerId: $scope.playerId}
		  })
	    .then(function(response) {
		console.log(response.data);
	    }, function(error){
		console.log(error);
	    });
	} else {
	    console.log("not allowed to make a mark")
	}
	console.log(row, col)
    }

    $scope.join = function(gameId) {
	console.log("joining game " + gameId)
	$scope.playerId = 2
	$http({method: "POST", url: "/join/" + gameId})
	    .then(function(response) {
		$scope.currentGame = response.data
		console.log(response.data);
		console.log("joined game " + gameId);
		$location.path('game')
		checkWebSocket()
	    }, function(error){
		console.log(error);
	    });	
    }
    
    $scope.createNewGame = function() {
	$scope.playerId = 1
	console.log('creating a new game');
	$http({method: "POST", url: "/create"})
	    .then(function(response) {
		console.log('new game has been created');
		$scope.currentGame = response.data
		console.log(response.data);
		$location.path('game')
		checkWebSocket()
	    }, function(error){
		console.log(error);
    });
    };

    console.log("requesting games");
    $http({
	method: "GET",
	url: "/listgames"
    }).then(function(response) {
	console.log(response.data);	
	$scope.games = response.data;
    }, function(error){
	console.log(error);
    });
    checkWebSocket()
};

angular.module('ttt', ['ngWebSocket', 'ngRoute']);
angular.module('ttt').config(['$routeProvider', '$locationProvider',
  function($routeProvider, $locationProvider) {
    $routeProvider
      .when('/', {
        templateUrl: 'list.template.html'
      })
      .when('/game', {
        templateUrl: 'board.template.html'
      });

//    $locationProvider.html5Mode(true);
  }])

angular.module('ttt').controller("TTTController", TTTController);
