import std/asyncdispatch
import std/os
import std/json
var needsReload*:bool;
proc buildPlugin*() =
  if (os.execShellCmd("sperm --version") != 0):
    echo("We couldn't find the sperm on your system. Please install sperm using `npm i -g sperm`")
  else:
    if (os.execShellCmd("sperm build") == 0):
      echo("Build finished")
    else:
      echo("Build failed.")
proc start*() {.async.}=
  var fileToWatch = parseJson(readFile("cumcord_manifest.json"))["file"].getStr()
  echo("Watching " & fileToWatch)
  while true:
    discard
    if (fileExists(".pluginCache") == false):
      writeFile(".pluginCache", readFile(fileToWatch))
    var current = readFile(fileToWatch)
    var cached = readFile(".pluginCache")
    if (cached != current):
      echo "Detected a source code change. Rebuilding the plugin."
      buildPlugin()
      writeFile(".pluginCache", readFile(fileToWatch))
      needsReload = true;
    await sleepAsync(500)
