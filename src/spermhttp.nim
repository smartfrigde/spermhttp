import std/asynchttpserver
import std/asyncdispatch
import std/os
import std/parseopt
import std/strutils
import FileWatcher
var port:int = 42069
var p = initOptParser()
  
proc main {.async.} =
  if (os.execShellCmd("sperm --version") != 0):
    echo("We couldn't find the sperm on your system. Please install sperm using `npm i -g sperm`")
  p.next()
  case p.kind
  of cmdEnd, cmdShortOption, cmdLongOption:
    echo("No port provided. Using default port 42069")
  of cmdArgument:
    echo "Using port: ", p.key
    port = parseInt(p.key)
  
  if (fileExists("cumcord_manifest.json") == false):
    echo("Couldn't find Cumcord plugin manifest, please create one for sperm http to function.")
    quit(1)
  var server = newAsyncHttpServer()
  proc cb(req: Request) {.async.} =
    #echo (req.reqMethod, req.url, req.headers)
    if (req.url.path == "/"):
      let headers = {"Content-type": "text/plain; charset=utf-8", "Access-Control-Allow-Origin": "*"}
      await req.respond(Http200, "sperm http", headers.newHttpHeaders())
    if (req.url.path == "/plugin.json"):
      let headers = {"Content-type": "text/json; charset=utf-8", "Access-Control-Allow-Origin": "*"}
      await req.respond(Http200, readFile("dist/plugin.json"), headers.newHttpHeaders())
      FileWatcher.needsReload = false;
    if (req.url.path == "/reload.json"):
      let headers = {"Content-type": "text/json; charset=utf-8", "Access-Control-Allow-Origin": "*"}
      if (FileWatcher.needsReload):
        await req.respond(Http200, """{"reload": true}""", headers.newHttpHeaders())
      else:
        await req.respond(Http200, """{"reload": false}""", headers.newHttpHeaders())
    if (req.url.path == "/plugin.js"):
      let headers = {"Content-type": "application/javascript; charset=utf-8", "Access-Control-Allow-Origin": "*"}
      await req.respond(Http200, readFile("dist/plugin.js"), headers.newHttpHeaders())
      FileWatcher.needsReload = false;
  FileWatcher.buildPlugin()
  server.listen(Port(port))
  let port = server.getPort
  echo "You can now develop this plugin using this code: " & $port.uint16
  while true:
    if server.shouldAcceptRequest():
      await server.acceptRequest(cb)
    else:
      # too many concurrent connections, `maxFDs` exceeded
      # wait 500ms for FDs to be closed
      await sleepAsync(500)
  
waitFor main() and FileWatcher.start()
