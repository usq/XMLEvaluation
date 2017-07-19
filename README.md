# Evaluation Repository

## Cloning from GitHub
- execute `git clone <url>`
- execute `git submodule update --init --recursive` to initialize and fetch all submodules


## Prerequisites
- The start scripts assume a *nix environment (linux, macos), but they are very simple and can be easily adapted for windows.
- To start the Hybrid application, [npm](https://www.npmjs.com) is required
- To start the AngularJS application, [mongodb](http://mongodb.com) is required

## Starting the Hybrid application
### Fetch node dependencies
- Fetch node dependencies by executing `npm install` in the `hybrid/basex/webapp/static/HybridRouter` folder

### Start BaseX and Node.js router
1. exectute the `start_basex` script in the `hybrid` folder, which just executes `./basex/bin/basexhttp`
2. exectute the `start_node` script in the `hybrid` folder, which executes `node basex/webapp/static/HybridRouter/router.js`



## Starting the modified BaseX application
1. execute `start_modified_basex` in the `modified_basex` folder, which just executes `sh basex/basex-api/etc/basexhttp`

## Starting the AngularJS application
### Fetch node dependencies
- Fetch node dependencies by executing `npm install` in the `javascript/server` folder

### Start MongoDB and Express
1. Execute `start_mongodb` in the `javascript` folder
2. Execute `start_node` in the `javascript` folder


## Troubleshooting
If BaseX does not return responses as expected, e.g. no changed responses are returned when the `.xqm` is changed, look for a `.basex` file in your home folder, which is generated by BaseX and contains the path to the webapp folder. Modify as needed.
